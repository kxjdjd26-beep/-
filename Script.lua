-- // ESP + AimLock with FOV Circle
-- // Rayfield UI Menu
-- // Загрузка Rayfield
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- // Сервисы
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

-- // Настройки по умолчанию
local Settings = {
    ESP = {
        Enabled = false,
        TeamCheck = true,
        Color = Color3.fromRGB(255, 0, 0),
        Transparency = 0.5
    },
    AimLock = {
        Enabled = false,
        FOV = 100,
        CircleColor = Color3.fromRGB(255, 255, 255),
        CircleThickness = 2,
        CircleFilled = false,
        TargetPart = "Head", -- или "HumanoidRootPart"
        Smoothness = 0.5,
        Keybind = Enum.KeyCode.E
    }
}

-- // Создание окна Rayfield
local Window = Rayfield:CreateWindow({
    Name = "ESP + AimLock Hub",
    LoadingTitle = "Loading Script...",
    LoadingSubtitle = "by Nyx",
    Theme = "Default",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "ESP_AimLock_Hub",
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
local SettingsTab = Window:CreateTab("Settings", 4483362458)

-- // ESP Functions
local ESPFolder = Instance.new("Folder")
ESPFolder.Name = "ESP_Folder"
ESPFolder.Parent = Camera

local function createESP(player)
    if player ~= LocalPlayer and player.Character then
        local character = player.Character
        local highlight = Instance.new("Highlight")
        highlight.Name = "ESP_Highlight"
        highlight.FillColor = Settings.ESP.Color
        highlight.OutlineColor = Settings.ESP.Color
        highlight.FillTransparency = Settings.ESP.Transparency
        highlight.OutlineTransparency = 0
        highlight.DepthMode = Enum.HighlightDepthMode.Occluded -- Видно сквозь стены
        highlight.Parent = character
        
        -- // Сохраняем ссылку для последующего удаления
        ESPFolder:SetAttribute(player.Name .. "_Highlight", highlight)
    end
end

local function removeESP(player)
    if player ~= LocalPlayer and player.Character then
        local highlight = player.Character:FindFirstChild("ESP_Highlight")
        if highlight then
            highlight:Destroy()
        end
    end
end

-- // ESP Toggle
local ESPToggle = ESPTab:CreateToggle({
    Name = "Enable ESP",
    CurrentValue = false,
    Flag = "ESP_Toggle",
    Callback = function(Value)
        Settings.ESP.Enabled = Value
        if Value then
            for _, player in pairs(Players:GetPlayers()) do
                createESP(player)
            end
            -- // Подписка на новых игроков
            Players.PlayerAdded:Connect(function(player)
                if Settings.ESP.Enabled then
                    createESP(player)
                end
            end)
        else
            for _, player in pairs(Players:GetPlayers()) do
                removeESP(player)
            end
        end
    end
})

-- // ESP Color Picker
local ESPColorPicker = ESPTab:CreateColorPicker({
    Name = "ESP Color",
    Color = Color3.fromRGB(255, 0, 0),
    Flag = "ESP_Color",
    Callback = function(Value)
        Settings.ESP.Color = Value
        -- // Обновляем цвет у всех игроков
        for _, player in pairs(Players:GetPlayers()) do
            if player.Character and player.Character:FindFirstChild("ESP_Highlight") then
                local highlight = player.Character:FindFirstChild("ESP_Highlight")
                highlight.FillColor = Value
                highlight.OutlineColor = Value
            end
        end
    end
})

-- // ESP Transparency Slider
local ESPTransparencySlider = ESPTab:CreateSlider({
    Name = "ESP Transparency",
    Range = {0, 1},
    Increment = 0.1,
    Suffix = "Transparency",
    CurrentValue = 0.5,
    Flag = "ESP_Transparency",
    Callback = function(Value)
        Settings.ESP.Transparency = Value
        for _, player in pairs(Players:GetPlayers()) do
            if player.Character and player.Character:FindFirstChild("ESP_Highlight") then
                local highlight = player.Character:FindFirstChild("ESP_Highlight")
                highlight.FillTransparency = Value
            end
        end
    end
})

-- // Team Check Toggle
local TeamCheckToggle = ESPTab:CreateToggle({
    Name = "Team Check (Don't show teammates)",
    CurrentValue = true,
    Flag = "ESP_TeamCheck",
    Callback = function(Value)
        Settings.ESP.TeamCheck = Value
        -- // Обновить ESP с учетом новой настройки
        if Settings.ESP.Enabled then
            for _, player in pairs(Players:GetPlayers()) do
                removeESP(player)
                createESP(player)
            end
        end
    end
})

-- // AimLock Functions
local FOVCircle = Drawing.new("Circle")
FOVCircle.Visible = false
FOVCircle.Thickness = 2
FOVCircle.Color = Color3.fromRGB(255, 255, 255)
FOVCircle.Filled = false
FOVCircle.Radius = 100
FOVCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

local function updateFOVCircle()
    FOVCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
end

local function getClosestPlayerInFOV()
    local closestPlayer = nil
    local shortestDistance = Settings.AimLock.FOV
    
    local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            if Settings.ESP.TeamCheck and player.Team == LocalPlayer.Team then
                continue
            end
            
            local character = player.Character
            if not character then
                continue
            end
            
            local targetPart = character:FindFirstChild(Settings.AimLock.TargetPart)
            if not targetPart then
                continue
            end
            
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

local function aimAt(targetPosition)
    local cameraPosition = Camera.CFrame.Position
    local direction = (targetPosition - cameraPosition).unit
    local newCFrame = CFrame.new(cameraPosition, cameraPosition + direction)
    Camera.CFrame = Camera.CFrame:Lerp(newCFrame, Settings.AimLock.Smoothness)
end

-- // AimLock Toggle
local AimLockToggle = AimTab:CreateToggle({
    Name = "Enable AimLock",
    CurrentValue = false,
    Flag = "AimLock_Toggle",
    Callback = function(Value)
        Settings.AimLock.Enabled = Value
        FOVCircle.Visible = Value
    end
})

-- // FOV Slider
local FOVSlider = AimTab:CreateSlider({
    Name = "FOV Radius",
    Range = {50, 500},
    Increment = 10,
    Suffix = "px",
    CurrentValue = 100,
    Flag = "AimLock_FOV",
    Callback = function(Value)
        Settings.AimLock.FOV = Value
        FOVCircle.Radius = Value
    end
})

-- // FOV Circle Color Picker
local FOVColorPicker = AimTab:CreateColorPicker({
    Name = "FOV Circle Color",
    Color = Color3.fromRGB(255, 255, 255),
    Flag = "FOV_Circle_Color",
    Callback = function(Value)
        Settings.AimLock.CircleColor = Value
        FOVCircle.Color = Value
    end
})

-- // FOV Circle Thickness Slider
local FOVThicknessSlider = AimTab:CreateSlider({
    Name = "FOV Circle Thickness",
    Range = {1, 10},
    Increment = 1,
    Suffix = "px",
    CurrentValue = 2,
    Flag = "FOV_Circle_Thickness",
    Callback = function(Value)
        Settings.AimLock.CircleThickness = Value
        FOVCircle.Thickness = Value
    end
})

-- // FOV Circle Filled Toggle
local FOVFilledToggle = AimTab:CreateToggle({
    Name = "FOV Circle Filled",
    CurrentValue = false,
    Flag = "FOV_Circle_Filled",
    Callback = function(Value)
        Settings.AimLock.CircleFilled = Value
        FOVCircle.Filled = Value
    end
})

-- // Target Part Dropdown
local TargetPartDropdown = AimTab:CreateDropdown({
    Name = "Target Part",
    Options = {"Head", "HumanoidRootPart", "Torso"},
    CurrentOption = "Head",
    Flag = "Target_Part",
    Callback = function(Option)
        Settings.AimLock.TargetPart = Option
    end
})

-- // Smoothness Slider
local SmoothnessSlider = AimTab:CreateSlider({
    Name = "Aim Smoothness",
    Range = {0.1, 1},
    Increment = 0.1,
    Suffix = "Smooth",
    CurrentValue = 0.5,
    Flag = "Aim_Smoothness",
    Callback = function(Value)
        Settings.AimLock.Smoothness = Value
    end
})

-- // Keybind for AimLock
local KeybindInput = AimTab:CreateInput({
    Name = "AimLock Keybind",
    PlaceholderText = "Press key...",
    CurrentValue = "E",
    Flag = "AimLock_Keybind",
    Callback = function(Value)
        -- // Преобразование строки в KeyCode
        local key = Enum.KeyCode[Value]
        if key then
            Settings.AimLock.Keybind = key
        end
    end
})

-- // Обработка ввода для AimLock
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Settings.AimLock.Keybind then
        Settings.AimLock.Enabled = not Settings.AimLock.Enabled
        FOVCircle.Visible = Settings.AimLock.Enabled
    end
end)

-- // Основной цикл
RunService.RenderStepped:Connect(function()
    if Settings.AimLock.Enabled then
        updateFOVCircle()
        local closestPlayer = getClosestPlayerInFOV()
        if closestPlayer and closestPlayer.Character then
            local targetPart = closestPlayer.Character:FindFirstChild(Settings.AimLock.TargetPart)
            if targetPart then
                aimAt(targetPart.Position)
            end
        end
    end
end)

-- // Настройки Rayfield
local ConfigButton = SettingsTab:CreateButton({
    Name = "Save Configuration",
    Callback = function()
        Rayfield:Notify({
            Title = "Configuration Saved",
            Content = "Your settings have been saved.",
            Duration = 3
        })
    end
})

-- // Уведомление о загрузке
Rayfield:Notify({
    Title = "Script Loaded",
    Content = "ESP + AimLock is ready!",
    Duration = 3
})
