-- ═══════════════════════════════════════════════════════
-- ESP + AimLock System
-- Roblox Executor | Rayfield GUI
-- ═══════════════════════════════════════════════════════

-- Зависимости: Rayfield UI Library (загружается через loadstring)
-- Executor: любой поддерживающий Drawing API + getgc + hookmetamethod

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local Camera = Workspace.CurrentCamera

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

-- ═══════════════════════════════════════════════════════
-- RAYFIELD UI SETUP
-- ═══════════════════════════════════════════════════════

local Rayfield = loadstring(game:HttpGet("https://raw.githubusercontent.com/shlexware/Rayfield/main/source"))()

local Window = Rayfield:CreateWindow({
    Name = "PEDRO | ESP + AimLock",
    LoadingTitle = "PEDRO v4",
    LoadingSubtitle = "Initializing systems...",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "PedroConfig",
        FileName = "ESPAimLock"
    },
    KeySystem = false
})

-- ═══════════════════════════════════════════════════════
-- CONFIGURATION
-- ═══════════════════════════════════════════════════════

local Config = {
    ESP = {
        Enabled = false,
        Boxes = true,
        Names = true,
        Distance = true,
        Health = true,
        Tracers = false,
        TeamCheck = true,
        BoxColor = Color3.fromRGB(255, 0, 0),
        NameColor = Color3.fromRGB(255, 255, 255),
        DistanceColor = Color3.fromRGB(200, 200, 200),
        HealthColorLow = Color3.fromRGB(255, 0, 0),
        HealthColorHigh = Color3.fromRGB(0, 255, 0),
        TracerColor = Color3.fromRGB(255, 255, 255),
        MaxDistance = 1000,
        BoxThickness = 1,
        TextSize = 14,
        Font = Drawing.Fonts.UI,
        FilledBoxes = false,
        BoxFillTransparency = 0.5,
        ShowTeammates = false
    },
    AimLock = {
        Enabled = false,
        Smoothness = 0.15, -- 0 = моментально, 1 = очень медленно
        FOV = 150,
        FOVVisible = true,
        FOVColor = Color3.fromRGB(255, 255, 255),
        FOVFillTransparency = 0.9,
        TeamCheck = true,
        TargetPart = "Head", -- Head, Torso, HumanoidRootPart
        WallCheck = false,
        ShowTarget = true,
        TargetColor = Color3.fromRGB(0, 255, 0),
        Priority = "Distance", -- Distance, Health, Crosshair
        LockKey = Enum.KeyCode.E,
        ToggleMode = false,
        StickToTarget = false
    }
}

-- ═══════════════════════════════════════════════════════
-- UTILITY FUNCTIONS
-- ═══════════════════════════════════════════════════════

local Utility = {}

function Utility.IsPlayerAlive(player)
    local character = player.Character
    if not character then return false end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    return humanoid and humanoid.Health > 0
end

function Utility.GetCharacterRoot(player)
    local character = player.Character
    if not character then return nil end
    return character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Torso")
end

function Utility.GetTargetPart(player)
    local character = player.Character
    if not character then return nil end
    return character:FindFirstChild(Config.AimLock.TargetPart)
end

function Utility.IsTeammate(player)
    if not Config.ESP.TeamCheck and not Config.AimLock.TeamCheck then return false end
    if player == LocalPlayer then return true end
    return player.Team == LocalPlayer.Team
end

function Utility.GetDistanceFromCamera(position)
    return (position - Camera.CFrame.Position).Magnitude
end

function Utility.WorldToScreen(position)
    local screenPos, onScreen = Camera:WorldToViewportPoint(position)
    return Vector2.new(screenPos.X, screenPos.Y), onScreen, screenPos.Z
end

function Utility.GetHealthPercentage(player)
    local character = player.Character
    if not character then return 0 end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return 0 end
    return humanoid.Health / humanoid.MaxHealth
end

function Utility.Get2DDistance(pointA, pointB)
    return (pointA - pointB).Magnitude
end

function Utility.IsPointInCircle(point, circleCenter, radius)
    return Utility.Get2DDistance(point, circleCenter) <= radius
end

function Utility.Lerp(a, b, t)
    return a + (b - a) * t
end

function Utility.LerpVector2(a, b, t)
    return Vector2.new(
        Utility.Lerp(a.X, b.X, t),
        Utility.Lerp(a.Y, b.Y, t)
    )
end

-- ═══════════════════════════════════════════════════════
-- DRAWING POOL MANAGER
-- ═══════════════════════════════════════════════════════

local DrawingPool = {}
DrawingPool.__index = DrawingPool

function DrawingPool.new(maxSize)
    local self = setmetatable({}, DrawingPool)
    self.available = {}
    self.inUse = {}
    self.maxSize = maxSize or 50
    return self
end

function DrawingPool:Acquire(drawingType)
    local obj
    if #self.available > 0 then
        obj = table.remove(self.available)
    else
        obj = Drawing.new(drawingType)
    end
    obj.Visible = false
    table.insert(self.inUse, obj)
    return obj
end

function DrawingPool:Release(obj)
    for i, v in ipairs(self.inUse) do
        if v == obj then
            table.remove(self.inUse, i)
            obj.Visible = false
            table.insert(self.available, obj)
            break
        end
    end
end

function DrawingPool:ReleaseAll()
    for _, obj in ipairs(self.inUse) do
        obj.Visible = false
        table.insert(self.available, obj)
    end
    self.inUse = {}
end

function DrawingPool:Destroy()
    for _, obj in ipairs(self.available) do
        obj:Remove()
    end
    for _, obj in ipairs(self.inUse) do
        obj:Remove()
    end
    self.available = {}
    self.inUse = {}
end

-- ═══════════════════════════════════════════════════════
-- ESP SYSTEM
-- ═══════════════════════════════════════════════════════

local ESPSystem = {}
ESPSystem.Players = {}
ESPSystem.Pools = {
    Boxes = DrawingPool.new(100),
    FilledBoxes = DrawingPool.new(100),
    Names = DrawingPool.new(100),
    Distances = DrawingPool.new(100),
    HealthBars = DrawingPool.new(100),
    HealthBarBackgrounds = DrawingPool.new(100),
    Tracers = DrawingPool.new(100)
}

local ESPObject = {}
ESPObject.__index = ESPObject

function ESPObject.new(player)
    local self = setmetatable({}, ESPObject)
    self.Player = player
    self.Drawings = {
        Box = nil,
        FilledBox = nil,
        Name = nil,
        Distance = nil,
        HealthBar = nil,
        HealthBarBackground = nil,
        Tracer = nil
    }
    self.LastUpdate = 0
    return self
end

function ESPObject:Init()
    self.Drawings.Box = ESPSystem.Pools.Boxes:Acquire("Square")
    self.Drawings.FilledBox = ESPSystem.Pools.FilledBoxes:Acquire("Square")
    self.Drawings.Name = ESPSystem.Pools.Names:Acquire("Text")
    self.Drawings.Distance = ESPSystem.Pools.Distances:Acquire("Text")
    self.Drawings.HealthBar = ESPSystem.Pools.HealthBars:Acquire("Square")
    self.Drawings.HealthBarBackground = ESPSystem.Pools.HealthBarBackgrounds:Acquire("Square")
    self.Drawings.Tracer = ESPSystem.Pools.Tracers:Acquire("Line")
end

function ESPObject:Update()
    if not Config.ESP.Enabled then
        self:Hide()
        return
    end

    if self.Player == LocalPlayer then
        self:Hide()
        return
    end

    if not Utility.IsPlayerAlive(self.Player) then
        self:Hide()
        return
    end

    if Config.ESP.TeamCheck and Utility.IsTeammate(self.Player) and not Config.ESP.ShowTeammates then
        self:Hide()
        return
    end

    local root = Utility.GetCharacterRoot(self.Player)
    if not root then
        self:Hide()
        return
    end

    local head = self.Player.Character:FindFirstChild("Head")
    if not head then
        self:Hide()
        return
    end

    local rootPos = root.Position
    local headPos = head.Position
    local distance = Utility.GetDistanceFromCamera(rootPos)

    if distance > Config.ESP.MaxDistance then
        self:Hide()
        return
    end

    local rootScreen, rootOnScreen, rootDepth = Utility.WorldToScreen(rootPos)
    local headScreen, headOnScreen, headDepth = Utility.WorldToScreen(headPos)

    if not rootOnScreen or not headOnScreen then
        self:Hide()
        return
    end

    local boxHeight = math.abs(rootScreen.Y - headScreen.Y) * 2.5
    local boxWidth = boxHeight * 0.6
    local boxPosition = Vector2.new(
        rootScreen.X - boxWidth / 2,
        rootScreen.Y - boxHeight / 2
    )

    -- Box
    if Config.ESP.Boxes then
        self.Drawings.Box.Visible = true
        self.Drawings.Box.Size = Vector2.new(boxWidth, boxHeight)
        self.Drawings.Box.Position = boxPosition
        self.Drawings.Box.Color = Config.ESP.BoxColor
        self.Drawings.Box.Thickness = Config.ESP.BoxThickness
        self.Drawings.Box.Filled = false
        self.Drawings.Box.Transparency = 1
        self.Drawings.Box.ZIndex = 1

        if Config.ESP.FilledBoxes then
            self.Drawings.FilledBox.Visible = true
            self.Drawings.FilledBox.Size = Vector2.new(boxWidth, boxHeight)
            self.Drawings.FilledBox.Position = boxPosition
            self.Drawings.FilledBox.Color = Config.ESP.BoxColor
            self.Drawings.FilledBox.Filled = true
            self.Drawings.FilledBox.Transparency = Config.ESP.BoxFillTransparency
            self.Drawings.FilledBox.ZIndex = 0
        else
            self.Drawings.FilledBox.Visible = false
        end
    else
        self.Drawings.Box.Visible = false
        self.Drawings.FilledBox.Visible = false
    end

    -- Name
    if Config.ESP.Names then
        self.Drawings.Name.Visible = true
        self.Drawings.Name.Text = self.Player.Name
        self.Drawings.Name.Position = Vector2.new(rootScreen.X, boxPosition.Y - 18)
        self.Drawings.Name.Size = Config.ESP.TextSize
        self.Drawings.Name.Color = Config.ESP.NameColor
        self.Drawings.Name.Outline = true
        self.Drawings.Name.OutlineColor = Color3.fromRGB(0, 0, 0)
        self.Drawings.Name.Center = true
        self.Drawings.Name.Font = Config.ESP.Font
        self.Drawings.Name.ZIndex = 2
    else
        self.Drawings.Name.Visible = false
    end

    -- Distance
    if Config.ESP.Distance then
        self.Drawings.Distance.Visible = true
        self.Drawings.Distance.Text = string.format("[%dm]", math.floor(distance))
        self.Drawings.Distance.Position = Vector2.new(rootScreen.X, boxPosition.Y + boxHeight + 2)
        self.Drawings.Distance.Size = Config.ESP.TextSize - 2
        self.Drawings.Distance.Color = Config.ESP.DistanceColor
        self.Drawings.Distance.Outline = true
        self.Drawings.Distance.OutlineColor = Color3.fromRGB(0, 0, 0)
        self.Drawings.Distance.Center = true
        self.Drawings.Distance.Font = Config.ESP.Font
        self.Drawings.Distance.ZIndex = 2
    else
        self.Drawings.Distance.Visible = false
    end

    -- Health Bar
    if Config.ESP.Health then
        local healthPercent = Utility.GetHealthPercentage(self.Player)
        local barHeight = boxHeight
        local barWidth = 3
        local barPos = Vector2.new(boxPosition.X - barWidth - 2, boxPosition.Y)

        self.Drawings.HealthBarBackground.Visible = true
        self.Drawings.HealthBarBackground.Size = Vector2.new(barWidth, barHeight)
        self.Drawings.HealthBarBackground.Position = barPos
        self.Drawings.HealthBarBackground.Color = Color3.fromRGB(50, 50, 50)
        self.Drawings.HealthBarBackground.Filled = true
        self.Drawings.HealthBarBackground.ZIndex = 1

        self.Drawings.HealthBar.Visible = true
        self.Drawings.HealthBar.Size = Vector2.new(barWidth, barHeight * healthPercent)
        self.Drawings.HealthBar.Position = Vector2.new(barPos.X, barPos.Y + barHeight * (1 - healthPercent))
        self.Drawings.HealthBar.Color = Config.ESP.HealthColorLow:Lerp(Config.ESP.HealthColorHigh, healthPercent)
        self.Drawings.HealthBar.Filled = true
        self.Drawings.HealthBar.ZIndex = 2
    else
        self.Drawings.HealthBar.Visible = false
        self.Drawings.HealthBarBackground.Visible = false
    end

    -- Tracer
    if Config.ESP.Tracers then
        local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
        self.Drawings.Tracer.Visible = true
        self.Drawings.Tracer.From = screenCenter
        self.Drawings.Tracer.To = rootScreen
        self.Drawings.Tracer.Color = Config.ESP.TracerColor
        self.Drawings.Tracer.Thickness = 1
        self.Drawings.Tracer.Transparency = 1
        self.Drawings.Tracer.ZIndex = 0
    else
        self.Drawings.Tracer.Visible = false
    end
end

function ESPObject:Hide()
    for _, drawing in pairs(self.Drawings) do
        if drawing then
            drawing.Visible = false
        end
    end
end

function ESPObject:Destroy()
    for key, drawing in pairs(self.Drawings) do
        if drawing then
            ESPSystem.Pools[key .. "s"]:Release(drawing)
            self.Drawings[key] = nil
        end
    end
end

function ESPSystem:Init()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local espObj = ESPObject.new(player)
            espObj:Init()
            self.Players[player] = espObj
        end
    end

    Players.PlayerAdded:Connect(function(player)
        if player ~= LocalPlayer then
            local espObj = ESPObject.new(player)
            espObj:Init()
            self.Players[player] = espObj
        end
    end)

    Players.PlayerRemoving:Connect(function(player)
        local espObj = self.Players[player]
        if espObj then
            espObj:Destroy()
            self.Players[player] = nil
        end
    end)

    RunService.RenderStepped:Connect(function()
        if not Config.ESP.Enabled then
            for _, espObj in pairs(self.Players) do
                espObj:Hide()
            end
            return
        end
        for _, espObj in pairs(self.Players) do
            espObj:Update()
        end
    end)
end

-- ═══════════════════════════════════════════════════════
-- AIMLOCK SYSTEM
-- ═══════════════════════════════════════════════════════

local AimLockSystem = {}
AimLockSystem.CurrentTarget = nil
AimLockSystem.IsLocked = false
AimLockSystem.FOVCircle = nil
AimLockSystem.TargetHighlight = nil

function AimLockSystem:Init()
    -- FOV Circle
    self.FOVCircle = Drawing.new("Circle")
    self.FOVCircle.Visible = false
    self.FOVCircle.Thickness = 1.5
    self.FOVCircle.NumSides = 64
    self.FOVCircle.Filled = true
    self.FOVCircle.Transparency = Config.AimLock.FOVFillTransparency
    self.FOVCircle.ZIndex = 0

    -- Target Highlight
    self.TargetHighlight = Drawing.new("Circle")
    self.TargetHighlight.Visible = false
    self.TargetHighlight.Thickness = 2
    self.TargetHighlight.NumSides = 32
    self.TargetHighlight.Filled = false
    self.TargetHighlight.Color = Config.AimLock.TargetColor
    self.TargetHighlight.ZIndex = 3

    -- Input handling
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.KeyCode == Config.AimLock.LockKey then
            if Config.AimLock.ToggleMode then
                self.IsLocked = not self.IsLocked
                if not self.IsLocked then
                    self.CurrentTarget = nil
                end
            else
                self.IsLocked = true
            end
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if not Config.AimLock.ToggleMode and input.KeyCode == Config.AimLock.LockKey then
            self.IsLocked = false
            self.CurrentTarget = nil
        end
    end)

    RunService.RenderStepped:Connect(function()
        self:Update()
    end)
end

function AimLockSystem:GetClosestPlayerToCursor()
    local closestPlayer = nil
    local closestScore = math.huge
    local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        if not Utility.IsPlayerAlive(player) then continue end
        if Config.AimLock.TeamCheck and Utility.IsTeammate(player) then continue end

        local targetPart = Utility.GetTargetPart(player)
        if not targetPart then continue end

        local screenPos, onScreen, depth = Utility.WorldToScreen(targetPart.Position)
        if not onScreen then continue end

        local distance2D = Utility.Get2DDistance(screenPos, screenCenter)
        if distance2D > Config.AimLock.FOV then continue end

        if Config.AimLock.WallCheck then
            local rayParams = RaycastParams.new()
            rayParams.FilterDescendantsInstances = {LocalPlayer.Character, player.Character}
            rayParams.FilterType = Enum.RaycastFilterType.Blacklist
            local rayResult = Workspace:Raycast(Camera.CFrame.Position, (targetPart.Position - Camera.CFrame.Position).Unit * 1000, rayParams)
            if rayResult then continue end
        end

        local score
        if Config.AimLock.Priority == "Distance" then
            score = distance2D
        elseif Config.AimLock.Priority == "Health" then
            score = 1 - Utility.GetHealthPercentage(player)
        elseif Config.AimLock.Priority == "Crosshair" then
            score = distance2D
        else
            score = distance2D
        end

        if score < closestScore then
            closestScore = score
            closestPlayer = player
        end
    end

    return closestPlayer
end

function AimLockSystem:Update()
    if not Config.AimLock.Enabled then
        self.FOVCircle.Visible = false
        self.TargetHighlight.Visible = false
        return
    end

    local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

    -- Update FOV Circle
    self.FOVCircle.Position = screenCenter
    self.FOVCircle.Radius = Config.AimLock.FOV
    self.FOVCircle.Visible = Config.AimLock.FOVVisible
    self.FOVCircle.Color = Config.AimLock.FOVColor
    self.FOVCircle.Transparency = Config.AimLock.FOVFillTransparency

    -- Get target
    if self.IsLocked then
        if Config.AimLock.StickToTarget and self.CurrentTarget then
            if not Utility.IsPlayerAlive(self.CurrentTarget) then
                self.CurrentTarget = nil
            else
                local targetPart = Utility.GetTargetPart(self.CurrentTarget)
                if targetPart then
                    local screenPos, onScreen = Utility.WorldToScreen(targetPart.Position)
                    if not onScreen or Utility.Get2DDistance(screenPos, screenCenter) > Config.AimLock.FOV then
                        self.CurrentTarget = nil
                    end
                else
                    self.CurrentTarget = nil
                end
            end
        end

        if not self.CurrentTarget then
            self.CurrentTarget = self:GetClosestPlayerToCursor()
        end
    else
        self.CurrentTarget = nil
    end

    -- Aim at target
    if self.CurrentTarget then
        local targetPart = Utility.GetTargetPart(self.CurrentTarget)
        if targetPart then
            local targetScreenPos = Utility.WorldToScreen(targetPart.Position)
            local targetCFrame = CFrame.new(Camera.CFrame.Position, targetPart.Position)

            if Config.AimLock.Smoothness <= 0 then
                Camera.CFrame = targetCFrame
            else
                local currentLook = Camera.CFrame.LookVector
                local targetLook = (targetPart.Position - Camera.CFrame.Position).Unit
                local smoothFactor = 1 - Config.AimLock.Smoothness
                local smoothedLook = currentLook:Lerp(targetLook, smoothFactor)
                Camera.CFrame = CFrame.new(Camera.CFrame.Position, Camera.CFrame.Position + smoothedLook)
            end

            -- Target highlight
            if Config.AimLock.ShowTarget then
                self.TargetHighlight.Position = targetScreenPos
                self.TargetHighlight.Radius = 8
                self.TargetHighlight.Visible = true
                self.TargetHighlight.Color = Config.AimLock.TargetColor
            else
                self.TargetHighlight.Visible = false
            end
        else
            self.TargetHighlight.Visible = false
        end
    else
        self.TargetHighlight.Visible = false
    end
end

-- ═══════════════════════════════════════════════════════
-- RAYFIELD GUI TABS
-- ═══════════════════════════════════════════════════════

local ESPTab = Window:CreateTab("ESP", "eye")
local AimTab = Window:CreateTab("AimLock", "crosshair")
local SettingsTab = Window:CreateTab("Settings", "settings")

-- ═══════════════════════════════════════════════════════
-- ESP TAB
-- ═══════════════════════════════════════════════════════

ESPTab:CreateToggle({
    Name = "Enable ESP",
    CurrentValue = false,
    Flag = "ESP_Enabled",
    Callback = function(Value)
        Config.ESP.Enabled = Value
    end
})

ESPTab:CreateToggle({
    Name = "Boxes",
    CurrentValue = true,
    Flag = "ESP_Boxes",
    Callback = function(Value)
        Config.ESP.Boxes = Value
    end
})

ESPTab:CreateToggle({
    Name = "Filled Boxes",
    CurrentValue = false,
    Flag = "ESP_FilledBoxes",
    Callback = function(Value)
        Config.ESP.FilledBoxes = Value
    end
})

ESPTab:CreateToggle({
    Name = "Names",
    CurrentValue = true,
    Flag = "ESP_Names",
    Callback = function(Value)
        Config.ESP.Names = Value
    end
})

ESPTab:CreateToggle({
    Name = "Distance",
    CurrentValue = true,
    Flag = "ESP_Distance",
    Callback = function(Value)
        Config.ESP.Distance = Value
    end
})

ESPTab:CreateToggle({
    Name = "Health Bar",
    CurrentValue = true,
    Flag = "ESP_Health",
    Callback = function(Value)
        Config.ESP.Health = Value
    end
})

ESPTab:CreateToggle({
    Name = "Tracers",
    CurrentValue = false,
    Flag = "ESP_Tracer",
    Callback = function(Value)
        Config.ESP.Tracers = Value
    end
})

ESPTab:CreateToggle({
    Name = "Team Check",
    CurrentValue = true,
    Flag = "ESP_TeamCheck",
    Callback = function(Value)
        Config.ESP.TeamCheck = Value
    end
})

ESPTab:CreateToggle({
    Name = "Show Teammates",
    CurrentValue = false,
    Flag = "ESP_ShowTeammates",
    Callback = function(Value)
        Config.ESP.ShowTeammates = Value
    end
})

ESPTab:CreateSlider({
    Name = "Max Distance",
    Range = {100, 5000},
    Increment = 100,
    Suffix = "m",
    CurrentValue = 1000,
    Flag = "ESP_MaxDistance",
    Callback = function(Value)
        Config.ESP.MaxDistance = Value
    end
})

ESPTab:CreateSlider({
    Name = "Box Thickness",
    Range = {1, 5},
    Increment = 0.5,
    Suffix = "px",
    CurrentValue = 1,
    Flag = "ESP_BoxThickness",
    Callback = function(Value)
        Config.ESP.BoxThickness = Value
    end
})

ESPTab:CreateSlider({
    Name = "Text Size",
    Range = {10, 24},
    Increment = 1,
    Suffix = "px",
    CurrentValue = 14,
    Flag = "ESP_TextSize",
    Callback = function(Value)
        Config.ESP.TextSize = Value
    end
})

ESPTab:CreateColorPicker({
    Name = "Box Color",
    Color = Config.ESP.BoxColor,
    Flag = "ESP_BoxColor",
    Callback = function(Value)
        Config.ESP.BoxColor = Value
    end
})

ESPTab:CreateColorPicker({
    Name = "Name Color",
    Color = Config.ESP.NameColor,
    Flag = "ESP_NameColor",
    Callback = function(Value)
        Config.ESP.NameColor = Value
    end
})

ESPTab:CreateColorPicker({
    Name = "Tracer Color",
    Color = Config.ESP.TracerColor,
    Flag = "ESP_TracerColor",
    Callback = function(Value)
        Config.ESP.TracerColor = Value
    end
})

-- ═══════════════════════════════════════════════════════
-- AIMLOCK TAB
-- ═══════════════════════════════════════════════════════

AimTab:CreateToggle({
    Name = "Enable AimLock",
    CurrentValue = false,
    Flag = "Aim_Enabled",
    Callback = function(Value)
        Config.AimLock.Enabled = Value
    end
})

AimTab:CreateSlider({
    Name = "Smoothness",
    Range = {0, 1},
    Increment = 0.01,
    Suffix = "",
    CurrentValue = 0.15,
    Flag = "Aim_Smoothness",
    Callback = function(Value)
        Config.AimLock.Smoothness = Value
    end
})

AimTab:CreateSlider({
    Name = "FOV Size",
    Range = {50, 500},
    Increment = 10,
    Suffix = "px",
    CurrentValue = 150,
    Flag = "Aim_FOV",
    Callback = function(Value)
        Config.AimLock.FOV = Value
    end
})

AimTab:CreateToggle({
    Name = "Show FOV Circle",
    CurrentValue = true,
    Flag = "Aim_FOVVisible",
    Callback = function(Value)
        Config.AimLock.FOVVisible = Value
    end
})

AimTab:CreateToggle({
    Name = "Team Check",
    CurrentValue = true,
    Flag = "Aim_TeamCheck",
    Callback = function(Value)
        Config.AimLock.TeamCheck = Value
    end
})

AimTab:CreateToggle({
    Name = "Wall Check",
    CurrentValue = false,
    Flag = "Aim_WallCheck",
    Callback = function(Value)
        Config.AimLock.WallCheck = Value
    end
})

AimTab:CreateToggle({
    Name = "Show Target",
    CurrentValue = true,
    Flag = "Aim_ShowTarget",
    Callback = function(Value)
        Config.AimLock.ShowTarget = Value
    end
})

AimTab:CreateToggle({
    Name = "Toggle Mode",
    CurrentValue = false,
    Flag = "Aim_ToggleMode",
    Callback = function(Value)
        Config.AimLock.ToggleMode = Value
    end
})

AimTab:CreateToggle({
    Name = "Stick to Target",
    CurrentValue = false,
    Flag = "Aim_StickToTarget",
    Callback = function(Value)
        Config.AimLock.StickToTarget = Value
    end
})

AimTab:CreateDropdown({
    Name = "Target Part",
    Options = {"Head", "Torso", "HumanoidRootPart"},
    CurrentOption = "Head",
    Flag = "Aim_TargetPart",
    Callback = function(Value)
        Config.AimLock.TargetPart = Value
    end
})

AimTab:CreateDropdown({
    Name = "Priority",
    Options = {"Distance", "Health", "Crosshair"},
    CurrentOption = "Distance",
    Flag = "Aim_Priority",
    Callback = function(Value)
        Config.AimLock.Priority = Value
    end
})

AimTab:CreateColorPicker({
    Name = "FOV Color",
    Color = Config.AimLock.FOVColor,
    Flag = "Aim_FOVColor",
    Callback = function(Value)
        Config.AimLock.FOVColor = Value
    end
})

AimTab:CreateColorPicker({
    Name = "Target Color",
    Color = Config.AimLock.TargetColor,
    Flag = "Aim_TargetColor",
    Callback = function(Value)
        Config.AimLock.TargetColor = Value
    end
})

-- ═══════════════════════════════════════════════════════
-- SETTINGS TAB
-- ═══════════════════════════════════════════════════════

SettingsTab:CreateKeybind({
    Name = "AimLock Key",
    CurrentKeybind = "E",
    HoldToInteract = false,
    Flag = "Aim_LockKey",
    Callback = function(Keybind)
        Config.AimLock.LockKey = Keybind
    end
})

SettingsTab:CreateButton({
    Name = "Unload Script",
    Callback = function()
        ESPSystem.Pools.Boxes:Destroy()
        ESPSystem.Pools.FilledBoxes:Destroy()
        ESPSystem.Pools.Names:Destroy()
        ESPSystem.Pools.Distances:Destroy()
        ESPSystem.Pools.HealthBars:Destroy()
        ESPSystem.Pools.HealthBarBackgrounds:Destroy()
        ESPSystem.Pools.Tracers:Destroy()
        if AimLockSystem.FOVCircle then
            AimLockSystem.FOVCircle:Remove()
        end
        if AimLockSystem.TargetHighlight then
            AimLockSystem.TargetHighlight:Remove()
        end
        Rayfield:Destroy()
    end
})

-- ═══════════════════════════════════════════════════════
-- INITIALIZATION
-- ═══════════════════════════════════════════════════════

ESPSystem:Init()
AimLockSystem:Init()

Rayfield:Notify({
    Title = "PEDRO | ESP + AimLock",
    Content = "System initialized successfully.",
    Duration = 3,
    Image = "check"
})

-- ═══════════════════════════════════════════════════════
-- END OF SCRIPT
-- ═══════════════════════════════════════════════════════
