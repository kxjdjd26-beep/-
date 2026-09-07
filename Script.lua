-- // ESP + AimLock v2 (Fixed)
-- // Загрузка Rayfield
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- // Сервисы
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

-- // Настройки
local Settings = {
    ESP = {
        Enabled = false,
        TeamCheck = true,
        Color = Color3.fromRGB(255, 0, 0),
        Transparency = 0.5,
        ShowDistance = true,
        ShowName = true
    },
    Aim = {
        Enabled = false,
        FOV = 150,
        Smoothness = 0.08,
        TargetPart = "Head",
        FOVColor = Color3.fromRGB(255, 255, 255),
        FOVThickness = 1,
        FOVFilled = false
    }
}

-- // Создание окна
local Window = Rayfield:CreateWindow({
    Name = "ESP + AimLock v2",
    LoadingTitle = "Loading...",
    LoadingSubtitle = "by Nyx",
    Theme = "Default",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "ESP_AimLock_v2",
        FileName = "Config"
    },
    KeySystem = false,
    KeySettings = {
        Title = "Key System",
        Subtitle = "Key System",
        Note = "No key required",
        FileName = "Key",
        SaveKey = true,
        GrabKeyFromSite = false,
        Key = {"Hello"}
    }
})

-- // Вкладки
local ESPTab = Window:CreateTab("ESP", 4483362458)
local AimTab = Window:CreateTab("AimLock", 4483362458)

-- // ========================================== ESP ==========================================

-- // Хранение всех Highlight
local ESPHighlights = {}

-- // Функция проверки, можно ли показывать ESP
local function canShowESP(player)
    if player == LocalPlayer then return false end
    if Settings.ESP.TeamCheck and player.Team == LocalPlayer.Team and player.Team ~= nil then
        return false
    end
    return true
end

-- // Создание Highlight для игрока
local function addHighlight(player)
    if ESPHighlights[player] then return end
    if not canShowESP(player) then return end

    local character = player.Character
    if not character then return end

    local highlight = Instance.new("Highlight")
    highlight.Name = "ESP_Highlight"
    highlight.FillColor = Settings.ESP.Color
    highlight.OutlineColor = Settings.ESP.Color
    highlight.FillTransparency = Settings.ESP.Transparency
    highlight.OutlineTransparency = 0
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop -- всегда видно
    highlight.Adornee = character -- привязка к персонажу
    highlight.Parent = character

    ESPHighlights[player] = highlight

    -- // BillboardGui для имени и дистанции
    if Settings.ESP.ShowName or Settings.ESP.ShowDistance then
        local billboard = Instance.new("BillboardGui")
        billboard.Name = "ESP_Billboard"
        billboard.Size = UDim2.new(0, 100, 0, 30)
        billboard.StudsOffset = Vector3.new(0, 2.5, 0)
        billboard.AlwaysOnTop = true
        billboard.Adornee = character:WaitForChild("Head")
        billboard.Parent = character

        local textLabel = Instance.new("TextLabel")
        textLabel.Size = UDim2.new(1, 0, 1, 0)
        textLabel.BackgroundTransparency = 1
        textLabel.TextColor3 = Settings.ESP.Color
        textLabel.TextStrokeTransparency = 0
        textLabel.TextSize = 12
        textLabel.Font = Enum.Font.SourceSansBold
        textLabel.Parent = billboard

        -- // Обновление текста
        task.spawn(function()
            while billboard.Parent and ESPHighlights[player] do
                local text = ""
                if Settings.ESP.ShowName then
                    text = player.Name
                end
                if Settings.ESP.ShowDistance and character:FindFirstChild("HumanoidRootPart") then
                    local dist = (character.HumanoidRootPart.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
                    text = text .. (text ~= "" and "\n" or "") .. "[" .. math.floor(dist) .. "m]"
                end
                textLabel.Text = text
                task.wait(0.1)
            end
        end)
    end
end

-- // Удаление Highlight у игрока
local function removeHighlight(player)
    if ESPHighlights[player] then
        ESPHighlights[player]:Destroy()
        ESPHighlights[player] = nil
    end
    -- // Удаляем Billboard
    if player.Character then
        local billboard = player.Character:FindFirstChild("ESP_Billboard")
        if billboard then billboard:Destroy() end
    end
end

-- // Включение ESP
local function enableESP()
    for _, player in pairs(Players:GetPlayers()) do
        addHighlight(player)
    end

    -- // Новые игроки
    Players.PlayerAdded:Connect(function(player)
        if Settings.ESP.Enabled then
            player.CharacterAdded:Connect(function()
                if Settings.ESP.Enabled then
                    task.wait(0.5) -- ждём загрузку персонажа
                    addHighlight(player)
                end
            end)
        end
    end)

    -- // Респавн существующих
    for _, player in pairs(Players:GetPlayers()) do
        player.CharacterAdded:Connect(function()
            if Settings.ESP.Enabled then
                task.wait(0.5)
                addHighlight(player)
            end
        end)
    end
end

-- // Выключение ESP
local function disableESP()
    for player, _ in pairs(ESPHighlights) do
        removeHighlight(player)
    end
end

-- // UI для ESP
local ESPToggle = ESPTab:CreateToggle({
    Name = "Enable ESP",
    CurrentValue = false,
    Flag = "ESP_Enabled",
    Callback = function(Value)
        Settings.ESP.Enabled = Value
        if Value then
            enableESP()
        else
            disableESP()
        end
    end
})

local ESPColorPicker = ESPTab:CreateColorPicker({
    Name = "ESP Color",
    Color = Color3.fromRGB(255, 0, 0),
    Flag = "ESP_Color",
    Callback = function(Value)
        Settings.ESP.Color = Value
        -- // Обновляем существующие
        for _, highlight in pairs(ESPHighlights) do
            highlight.FillColor = Value
            highlight.OutlineColor = Value
        end
    end
})

local ESPTransparencySlider = ESPTab:CreateSlider({
    Name = "ESP Fill Transparency",
    Range = {0, 1},
    Increment = 0.1,
    Suffix = "",
    CurrentValue = 0.5,
    Flag = "ESP_Transparency",
    Callback = function(Value)
        Settings.ESP.Transparency = Value
        for _, highlight in pairs(ESPHighlights) do
            highlight.FillTransparency = Value
        end
    end
})

local ESPTeamCheckToggle = ESPTab:CreateToggle({
    Name = "Team Check (Skip Teammates)",
    CurrentValue = true,
    Flag = "ESP_TeamCheck",
    Callback = function(Value)
        Settings.ESP.TeamCheck = Value
    end
})

local ESPNameToggle = ESPTab:CreateToggle({
    Name = "Show Player Name",
    CurrentValue = true,
    Flag = "ESP_ShowName",
    Callback = function(Value)
        Settings.ESP.ShowName = Value
    end
})

local ESPDistanceToggle = ESPTab:CreateToggle({
    Name = "Show Distance",
    CurrentValue = true,
    Flag = "ESP_ShowDistance",
    Callback = function(Value)
        Settings.ESP.ShowDistance = Value
    end
})

-- // ========================================== AIMLOCK ==========================================

-- // FOV Circle
local FOVCircle = Drawing.new("Circle")
FOVCircle.Visible = false
FOVCircle.Thickness = 1
FOVCircle.Color = Color3.fromRGB(255, 255, 255)
FOVCircle.Filled = false
FOVCircle.Radius = 150
FOVCircle.NumSides = 100

-- // Обновление позиции FOV Circle
RunService.RenderStepped:Connect(function()
    local Camera = workspace.CurrentCamera
    FOVCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
end)

-- // Поиск ближайшего игрока в FOV
local function getClosestPlayer()
    local Camera = workspace.CurrentCamera
    local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    local closestPlayer = nil
    local shortestDistance = Settings.Aim.FOV

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            if Settings.ESP.TeamCheck and player.Team == LocalPlayer.Team and player.Team ~= nil then
                continue
            end

            local character = player.Character
            if not character then continue end

            local targetPart = character:FindFirstChild(Settings.Aim.TargetPart)
            if not targetPart then continue end

            local screenPos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
            if onScreen then
                local distance = (Vector2.new(screenPos.X, screenPos.Y) - screenCenter).Magnitude
                if distance < shortestDistance then
                    shortestDistance = distance
                    closestPlayer = player
                end
            end
        end
    end

    return closestPlayer
end

-- // Плавное наведение камеры
local function smoothAim(targetPart)
    local Camera = workspace.CurrentCamera
    local cameraPosition = Camera.CFrame.Position

    -- // Направление к цели
    local targetPosition = targetPart.Position
    local direction = (targetPosition - cameraPosition).Unit

    -- // Целевой CFrame
    local targetCFrame = CFrame.new(cameraPosition, targetPosition)

    -- // Плавная интерполяция
    Camera.CFrame = Camera.CFrame:Lerp(targetCFrame, Settings.Aim.Smoothness)
end

-- // Основной цикл AimLock
RunService.RenderStepped:Connect(function()
    if Settings.Aim.Enabled then
        local closest = getClosestPlayer()
        if closest and closest.Character then
            local targetPart = closest.Character:FindFirstChild(Settings.Aim.TargetPart)
            if targetPart then
                smoothAim(targetPart)
            end
        end
    end
end)

-- // UI для AimLock
local AimToggle = AimTab:CreateToggle({
    Name = "Enable AimLock",
    CurrentValue = false,
    Flag = "Aim_Enabled",
    Callback = function(Value)
        Settings.Aim.Enabled = Value
        FOVCircle.Visible = Value
    end
})

local FOVSlider = AimTab:CreateSlider({
    Name = "FOV Radius (pixels)",
    Range = {50, 500},
    Increment = 10,
    Suffix = "px",
    CurrentValue = 150,
    Flag = "Aim_FOV",
    Callback = function(Value)
        Settings.Aim.FOV = Value
        FOVCircle.Radius = Value
    end
})

local SmoothnessSlider = AimTab:CreateSlider({
    Name = "Aim Smoothness",
    Range = {0.01, 0.3},
    Increment = 0.01,
    Suffix = "",
    CurrentValue = 0.08,
    Flag = "Aim_Smoothness",
    Callback = function(Value)
        Settings.Aim.Smoothness = Value
    end
})

local TargetPartDropdown = AimTab:CreateDropdown({
    Name = "Target Part",
    Options = {"Head", "HumanoidRootPart", "Torso", "UpperTorso"},
    CurrentOption = "Head",
    Flag = "Aim_TargetPart",
    Callback = function(Option)
        Settings.Aim.TargetPart = Option
    end
})

local FOVColorPicker = AimTab:CreateColorPicker({
    Name = "FOV Circle Color",
    Color = Color3.fromRGB(255, 255, 255),
    Flag = "Aim_FOVColor",
    Callback = function(Value)
        Settings.Aim.FOVColor = Value
        FOVCircle.Color = Value
    end
})

local FOVThicknessSlider = AimTab:CreateSlider({
    Name = "FOV Circle Thickness",
    Range = {1, 5},
    Increment = 1,
    Suffix = "px",
    CurrentValue = 1,
    Flag = "Aim_FOVThickness",
    Callback = function(Value)
        Settings.Aim.FOVThickness = Value
        FOVCircle.Thickness = Value
    end
})

local FOVFilledToggle = AimTab:CreateToggle({
    Name = "FOV Circle Filled",
    CurrentValue = false,
    Flag = "Aim_FOVFilled",
    Callback = function(Value)
        Settings.Aim.FOVFilled = Value
        FOVCircle.Filled = Value
    end
})

-- // Keybind для AimLock (переключение по клавише)
local aimKeybind = Enum.KeyCode.E

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == aimKeybind then
        Settings.Aim.Enabled = not Settings.Aim.Enabled
        FOVCircle.Visible = Settings.Aim.Enabled
    end
end)

-- // Настройка keybind через UI
local KeybindSection = AimTab:CreateSection("Keybind Settings")

local KeybindDropdown = AimTab:CreateDropdown({
    Name = "AimLock Toggle Key",
    Options = {"E", "Q", "F", "C", "V", "X", "Z", "T", "G", "H"},
    CurrentOption = "E",
    Flag = "Aim_Keybind",
    Callback = function(Option)
        aimKeybind = Enum.KeyCode[Option]
    end
})

-- // Уведомление
Rayfield:Notify({
    Title = "Script Loaded",
    Content = "ESP + AimLock v2 Ready!",
    Duration = 3
})
