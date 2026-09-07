--[[
    Universal Aimbot + ESP
    GUI: Rayfield
    Fixed Aimbot + FOV Circle + Name Toggle
    Compatible with Delta and most executors
]]

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()

-- ====================== SETTINGS ======================
local Settings = {
    -- Aimbot
    AimbotEnabled = false,
    AimbotKey = Enum.UserInputType.MouseButton2,
    AimPart = "Head",
    Smoothness = 0.2,
    FOV = 180,
    WallCheck = false,
    TeamCheckAim = true,
    ShowFOV = true,

    -- ESP
    ESPEnabled = false,
    TeamCheckESP = true,
    BoxESP = true,
    HealthESP = true,
    DistanceESP = true,
    NameESP = true,
    ESPColor = Color3.fromRGB(255, 50, 50),
    TeamColor = Color3.fromRGB(50, 150, 255),
}

-- ====================== FOV CIRCLE ======================
local FOVCircle = Drawing.new("Circle")
FOVCircle.Thickness = 1.5
FOVCircle.NumSides = 64
FOVCircle.Radius = Settings.FOV
FOVCircle.Filled = false
FOVCircle.Visible = false
FOVCircle.Color = Color3.fromRGB(255, 255, 255)
FOVCircle.Transparency = 1

RunService.RenderStepped:Connect(function()
    local mousePos = UserInputService:GetMouseLocation()
    FOVCircle.Position = mousePos
    FOVCircle.Radius = Settings.FOV
    FOVCircle.Visible = Settings.AimbotEnabled and Settings.ShowFOV
end)

-- ====================== AIMBOT ======================
local function IsVisible(targetPart)
    if not Settings.WallCheck then return true end

    local origin = Camera.CFrame.Position
    local direction = (targetPart.Position - origin)
    local rayParams = RaycastParams.new()
    rayParams.FilterDescendantsInstances = {LocalPlayer.Character, Camera}
    rayParams.FilterType = Enum.RaycastFilterType.Blacklist

    local result = workspace:Raycast(origin, direction, rayParams)
    if result then
        return result.Instance and result.Instance:IsDescendantOf(targetPart.Parent)
    end
    return true
end

local function GetClosestPlayer()
    local closest = nil
    local shortest = Settings.FOV
    local mousePos = UserInputService:GetMouseLocation()

    for _, player in pairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        if not player.Character then continue end

        local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
        local root = player.Character:FindFirstChild("HumanoidRootPart")
        local part = player.Character:FindFirstChild(Settings.AimPart) or root

        if not humanoid or not part or humanoid.Health <= 0 then continue end
        if Settings.TeamCheckAim and player.Team and LocalPlayer.Team and player.Team == LocalPlayer.Team then continue end

        local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)
        if not onScreen then continue end

        local dist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
        if dist < shortest then
            if IsVisible(part) then
                shortest = dist
                closest = part
            end
        end
    end

    return closest
end

local aiming = false

UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.UserInputType == Settings.AimbotKey then
        aiming = true
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Settings.AimbotKey then
        aiming = false
    end
end)

RunService.RenderStepped:Connect(function()
    if Settings.AimbotEnabled and aiming then
        local target = GetClosestPlayer()
        if target then
            local currentCF = Camera.CFrame
            local targetCF = CFrame.new(currentCF.Position, target.Position)
            Camera.CFrame = currentCF:Lerp(targetCF, Settings.Smoothness)
        end
    end
end)

-- ====================== ESP ======================
local ESPObjects = {}

local function RemoveESP(player)
    if ESPObjects[player] then
        for _, obj in pairs(ESPObjects[player]) do
            pcall(function()
                if obj and obj.Remove then
                    obj:Remove()
                end
            end)
        end
        ESPObjects[player] = nil
    end
end

local function CreateESP(player)
    if player == LocalPlayer then return end
    RemoveESP(player)

    local box = Drawing.new("Square")
    box.Thickness = 1
    box.Filled = false
    box.Visible = false

    local nameText = Drawing.new("Text")
    nameText.Size = 14
    nameText.Center = true
    nameText.Outline = true
    nameText.Visible = false

    local healthText = Drawing.new("Text")
    healthText.Size = 13
    healthText.Center = true
    healthText.Outline = true
    healthText.Visible = false

    local distText = Drawing.new("Text")
    distText.Size = 12
    distText.Center = true
    distText.Outline = true
    distText.Visible = false

    ESPObjects[player] = {
        Box = box,
        Name = nameText,
        Health = healthText,
        Distance = distText
    }
end

local function UpdateESP()
    for _, player in pairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end

        if not ESPObjects[player] then
            CreateESP(player)
        end

        local objects = ESPObjects[player]
        if not objects then continue end

        local char = player.Character
        local humanoid = char and char:FindFirstChildOfClass("Humanoid")
        local root = char and char:FindFirstChild("HumanoidRootPart")
        local head = char and char:FindFirstChild("Head")

        if not Settings.ESPEnabled or not char or not humanoid or not root or humanoid.Health <= 0 then
            objects.Box.Visible = false
            objects.Name.Visible = false
            objects.Health.Visible = false
            objects.Distance.Visible = false
            continue
        end

        if Settings.TeamCheckESP and player.Team and LocalPlayer.Team and player.Team == LocalPlayer.Team then
            objects.Box.Visible = false
            objects.Name.Visible = false
            objects.Health.Visible = false
            objects.Distance.Visible = false
            continue
        end

        local color = Settings.ESPColor
        if player.Team and LocalPlayer.Team and player.Team == LocalPlayer.Team then
            color = Settings.TeamColor
        end

        local headPos = head and head.Position or (root.Position + Vector3.new(0, 2.5, 0))
        local topPos, topOnScreen = Camera:WorldToViewportPoint(headPos)
        local bottomPos, bottomOnScreen = Camera:WorldToViewportPoint(root.Position - Vector3.new(0, 3, 0))

        if topOnScreen or bottomOnScreen then
            local height = math.abs(topPos.Y - bottomPos.Y)
            local width = height * 0.45

            -- Box
            if Settings.BoxESP then
                objects.Box.Size = Vector2.new(width, height)
                objects.Box.Position = Vector2.new(topPos.X - width / 2, topPos.Y)
                objects.Box.Color = color
                objects.Box.Visible = true
            else
                objects.Box.Visible = false
            end

            -- Name
            if Settings.NameESP then
                objects.Name.Text = player.Name
                objects.Name.Position = Vector2.new(topPos.X, topPos.Y - 18)
                objects.Name.Color = color
                objects.Name.Visible = true
            else
                objects.Name.Visible = false
            end

            -- Health
            if Settings.HealthESP then
                objects.Health.Text = math.floor(humanoid.Health) .. " HP"
                objects.Health.Position = Vector2.new(topPos.X, topPos.Y - 32)
                objects.Health.Color = color
                objects.Health.Visible = true
            else
                objects.Health.Visible = false
            end

            -- Distance
            if Settings.DistanceESP then
                local dist = (root.Position - Camera.CFrame.Position).Magnitude
                objects.Distance.Text = math.floor(dist) .. "m"
                objects.Distance.Position = Vector2.new(topPos.X, bottomPos.Y + 4)
                objects.Distance.Color = color
                objects.Distance.Visible = true
            else
                objects.Distance.Visible = false
            end
        else
            objects.Box.Visible = false
            objects.Name.Visible = false
            objects.Health.Visible = false
            objects.Distance.Visible = false
        end
    end
end

RunService.RenderStepped:Connect(UpdateESP)

Players.PlayerAdded:Connect(CreateESP)
Players.PlayerRemoving:Connect(RemoveESP)

for _, player in pairs(Players:GetPlayers()) do
    CreateESP(player)
end

-- ====================== RAYFIELD GUI ======================
local Window = Rayfield:CreateWindow({
    Name = "Aimbot + ESP",
    LoadingTitle = "Loading...",
    LoadingSubtitle = "fixed version",
    ConfigurationSaving = {
        Enabled = false,
    },
    KeySystem = false,
})

-- AIMBOT TAB
local AimTab = Window:CreateTab("Aimbot", 4483362458)

AimTab:CreateToggle({
    Name = "Enable Aimbot",
    CurrentValue = false,
    Flag = "AimbotEnabled",
    Callback = function(Value)
        Settings.AimbotEnabled = Value
    end,
})

AimTab:CreateToggle({
    Name = "Show FOV Circle",
    CurrentValue = true,
    Flag = "ShowFOV",
    Callback = function(Value)
        Settings.ShowFOV = Value
    end,
})

AimTab:CreateSlider({
    Name = "Smoothness",
    Range = {0.05, 1},
    Increment = 0.01,
    Suffix = "",
    CurrentValue = 0.2,
    Flag = "Smoothness",
    Callback = function(Value)
        Settings.Smoothness = Value
    end,
})

AimTab:CreateSlider({
    Name = "FOV",
    Range = {50, 500},
    Increment = 5,
    Suffix = "px",
    CurrentValue = 180,
    Flag = "FOV",
    Callback = function(Value)
        Settings.FOV = Value
        FOVCircle.Radius = Value
    end,
})

AimTab:CreateToggle({
    Name = "Wall Check",
    CurrentValue = false,
    Flag = "WallCheck",
    Callback = function(Value)
        Settings.WallCheck = Value
    end,
})

AimTab:CreateToggle({
    Name = "Team Check (Aimbot)",
    CurrentValue = true,
    Flag = "TeamCheckAim",
    Callback = function(Value)
        Settings.TeamCheckAim = Value
    end,
})

AimTab:CreateDropdown({
    Name = "Aim Part",
    Options = {"Head", "HumanoidRootPart", "UpperTorso", "Torso"},
    CurrentOption = {"Head"},
    Flag = "AimPart",
    Callback = function(Value)
        Settings.AimPart = typeof(Value) == "table" and Value[1] or Value
    end,
})

-- ESP TAB
local ESPTab = Window:CreateTab("ESP", 4483362458)

ESPTab:CreateToggle({
    Name = "Enable ESP",
    CurrentValue = false,
    Flag = "ESPEnabled",
    Callback = function(Value)
        Settings.ESPEnabled = Value
    end,
})

ESPTab:CreateToggle({
    Name = "Team Check",
    CurrentValue = true,
    Flag = "TeamCheckESP",
    Callback = function(Value)
        Settings.TeamCheckESP = Value
    end,
})

ESPTab:CreateToggle({
    Name = "Boxes",
    CurrentValue = true,
    Flag = "BoxESP",
    Callback = function(Value)
        Settings.BoxESP = Value
    end,
})

ESPTab:CreateToggle({
    Name = "Names",
    CurrentValue = true,
    Flag = "NameESP",
    Callback = function(Value)
        Settings.NameESP = Value
    end,
})

ESPTab:CreateToggle({
    Name = "Health",
    CurrentValue = true,
    Flag = "HealthESP",
    Callback = function(Value)
        Settings.HealthESP = Value
    end,
})

ESPTab:CreateToggle({
    Name = "Distance",
    CurrentValue = true,
    Flag = "DistanceESP",
    Callback = function(Value)
        Settings.DistanceESP = Value
    end,
})

ESPTab:CreateColorPicker({
    Name = "ESP Color",
    Color = Color3.fromRGB(255, 50, 50),
    Flag = "ESPColor",
    Callback = function(Value)
        Settings.ESPColor = Value
    end,
})

print("Aimbot + ESP loaded | FOV Circle + Name Toggle fixed")
