-- Roblox ESP + Aimlock Script
-- GUI: Rayfield Library
-- Target: Roblox Executor (e.g. Synapse X, KRNL, Fluxus)
-- Platform: Windows, Roblox Client
-- Arch: Lua 5.1 (Luau)

-- ══════════════════════════════════════════
--           RAYFIELD LOADER
-- ══════════════════════════════════════════

local Rayfield = loadstring(game:HttpGet(
    'https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "🎯 NebulaX | ESP + Aimlock",
    LoadingTitle = "NebulaX Suite",
    LoadingSubtitle = "by brody",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "NebulaX",
        FileName = "config"
    },
    KeySystem = false
})

-- ══════════════════════════════════════════
--           STATE / CONFIG
-- ══════════════════════════════════════════

local Config = {
    -- ESP
    ESP_Enabled       = true,
    ESP_Boxes         = true,
    ESP_Names         = true,
    ESP_Health        = true,
    ESP_Distance      = true,
    ESP_Tracers       = false,
    ESP_TeamCheck     = true,
    ESP_MaxDist       = 500,

    ESP_BoxColor      = Color3.fromRGB(255, 50, 50),
    ESP_NameColor     = Color3.fromRGB(255, 255, 255),
    ESP_HealthColor   = Color3.fromRGB(50, 255, 50),
    ESP_TracerColor   = Color3.fromRGB(255, 200, 0),

    -- Aimlock
    AIM_Enabled       = false,
    AIM_FOV           = 120,
    AIM_ShowFOV       = true,
    AIM_Smoothness    = 0.15,
    AIM_TargetPart    = "Head",
    AIM_TeamCheck     = true,
    AIM_HoldKey       = Enum.UserInputType.MouseButton2,
}

-- ══════════════════════════════════════════
--           SERVICES
-- ══════════════════════════════════════════

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera           = workspace.CurrentCamera
local LocalPlayer      = Players.LocalPlayer

-- ══════════════════════════════════════════
--           ESP DRAWING POOL
-- ══════════════════════════════════════════

local ESPObjects = {}

local function NewDraw(type, props)
    local d = Drawing.new(type)
    for k, v in pairs(props) do d[k] = v end
    return d
end

local function CreateESP(player)
    ESPObjects[player] = {
        Box = NewDraw("Square", {
            Visible = false, Color = Config.ESP_BoxColor,
            Thickness = 1.5, Filled = false
        }),
        Name = NewDraw("Text", {
            Visible = false, Color = Config.ESP_NameColor,
            Size = 14, Center = true, Outline = true,
            OutlineColor = Color3.new(0,0,0)
        }),
        Health = NewDraw("Square", {
            Visible = false, Color = Config.ESP_HealthColor,
            Thickness = 0, Filled = true
        }),
        HealthBG = NewDraw("Square", {
            Visible = false, Color = Color3.fromRGB(30,30,30),
            Thickness = 0, Filled = true
        }),
        Dist = NewDraw("Text", {
            Visible = false, Color = Color3.fromRGB(200,200,200),
            Size = 12, Center = true, Outline = true,
            OutlineColor = Color3.new(0,0,0)
        }),
        Tracer = NewDraw("Line", {
            Visible = false, Color = Config.ESP_TracerColor,
            Thickness = 1
        }),
    }
end

local function RemoveESP(player)
    if ESPObjects[player] then
        for _, d in pairs(ESPObjects[player]) do
            d:Remove()
        end
        ESPObjects[player] = nil
    end
end

for _, p in ipairs(Players:GetPlayers()) do
    if p ~= LocalPlayer then CreateESP(p) end
end
Players.PlayerAdded:Connect(function(p)
    if p ~= LocalPlayer then CreateESP(p) end
end)
Players.PlayerRemoving:Connect(RemoveESP)

-- ══════════════════════════════════════════
--           FOV CIRCLE
-- ══════════════════════════════════════════

local FOVCircle = Drawing.new("Circle")
FOVCircle.Visible   = false
FOVCircle.Radius    = Config.AIM_FOV
FOVCircle.Color     = Color3.fromRGB(255, 255, 255)
FOVCircle.Thickness = 1
FOVCircle.Filled    = false
FOVCircle.NumSides  = 64

local ViewportCenter = Vector2.new(
    Camera.ViewportSize.X / 2,
    Camera.ViewportSize.Y / 2
)

Camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
    ViewportCenter = Vector2.new(
        Camera.ViewportSize.X / 2,
        Camera.ViewportSize.Y / 2
    )
end)

-- ══════════════════════════════════════════
--           HELPERS
-- ══════════════════════════════════════════

local function GetRootAndHRP(player)
    local char = player.Character
    if not char then return nil, nil end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    return hrp, hum
end

local function IsEnemy(player)
    if not Config.AIM_TeamCheck and not Config.ESP_TeamCheck then return true end
    return player.Team ~= LocalPlayer.Team
end

local function WorldToScreen(pos)
    local screen, onScreen = Camera:WorldToViewportPoint(pos)
    return Vector2.new(screen.X, screen.Y), onScreen, screen.Z
end

local function GetBoundingBox(character)
    local minX, minY =  math.huge,  math.huge
    local maxX, maxY = -math.huge, -math.huge
    local anyOnScreen = false

    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") then
            local corners = {
                part.CFrame * CFrame.new( part.Size / 2),
                part.CFrame * CFrame.new(-part.Size / 2),
                part.CFrame * CFrame.new(
                     part.Size.X/2, -part.Size.Y/2,  part.Size.Z/2),
                part.CFrame * CFrame.new(
                    -part.Size.X/2,  part.Size.Y/2, -part.Size.Z/2),
            }
            for _, cf in ipairs(corners) do
                local sp, on = WorldToScreen(cf.Position)
                if on then
                    anyOnScreen = true
                    if sp.X < minX then minX = sp.X end
                    if sp.Y < minY then minY = sp.Y end
                    if sp.X > maxX then maxX = sp.X end
                    if sp.Y > maxY then maxY = sp.Y end
                end
            end
        end
    end

    return anyOnScreen, minX, minY, maxX, maxY
end

-- ══════════════════════════════════════════
--           AIMLOCK TARGET SELECTION
-- ══════════════════════════════════════════

local function GetClosestTarget()
    local bestPlayer = nil
    local bestDist   = Config.AIM_FOV

    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        if Config.AIM_TeamCheck and not IsEnemy(player) then continue end

        local char = player.Character
        if not char then continue end

        local part = char:FindFirstChild(Config.AIM_TargetPart)
            or char:FindFirstChild("HumanoidRootPart")
        if not part then continue end

        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum or hum.Health <= 0 then continue end

        local sp, onScreen = WorldToScreen(part.Position)
        if not onScreen then continue end

        local dist = (sp - ViewportCenter).Magnitude
        if dist < bestDist then
            bestDist   = dist
            bestPlayer = player
        end
    end

    return bestPlayer
end

-- ══════════════════════════════════════════
--           INPUT HANDLING
-- ══════════════════════════════════════════

local AimHeld = false

UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.UserInputType == Config.AIM_HoldKey then
        AimHeld = true
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Config.AIM_HoldKey then
        AimHeld = false
    end
end)

-- ══════════════════════════════════════════
--           MAIN RENDER LOOP
-- ══════════════════════════════════════════

RunService.RenderStepped:Connect(function()

    -- ── FOV Circle ──────────────────────────────────
    FOVCircle.Position = ViewportCenter
    FOVCircle.Radius   = Config.AIM_FOV
    FOVCircle.Visible  = Config.AIM_Enabled and Config.AIM_ShowFOV

    -- ── Aimlock (Camera CFrame lerp) ────────────────
    if Config.AIM_Enabled and AimHeld then
        local target = GetClosestTarget()
        if target then
            local char = target.Character
            local part = char and (
                char:FindFirstChild(Config.AIM_TargetPart)
                or char:FindFirstChild("HumanoidRootPart")
            )
            if part then
                local targetPos = part.Position
                local camCF     = Camera.CFrame
                local direction = (targetPos - camCF.Position).Unit
                local goalCF    = CFrame.new(camCF.Position, camCF.Position + direction)

                -- Плавный lerp камеры на цель
                Camera.CFrame = camCF:Lerp(goalCF, Config.AIM_Smoothness)
            end
        end
    end

    -- ── ESP ─────────────────────────────────────────
    for player, draws in pairs(ESPObjects) do
        local visible = false

        if Config.ESP_Enabled then
            local char = player.Character
            local hrp, hum = GetRootAndHRP(player)

            if char and hrp and hum and hum.Health > 0 then
                local camPos    = Camera.CFrame.Position
                local worldDist = (hrp.Position - camPos).Magnitude

                if worldDist <= Config.ESP_MaxDist then
                    if not Config.ESP_TeamCheck or IsEnemy(player) then

                        local onScreen, minX, minY, maxX, maxY =
                            GetBoundingBox(char)

                        if onScreen then
                            visible = true
                            local w = maxX - minX
                            local h = maxY - minY

                            -- Box
                            if Config.ESP_Boxes then
                                draws.Box.Visible  = true
                                draws.Box.Color    = Config.ESP_BoxColor
                                draws.Box.Position = Vector2.new(minX, minY)
                                draws.Box.Size     = Vector2.new(w, h)
                            else
                                draws.Box.Visible = false
                            end

                            -- Name
                            if Config.ESP_Names then
                                draws.Name.Visible  = true
                                draws.Name.Color    = Config.ESP_NameColor
                                draws.Name.Text     = player.Name
                                draws.Name.Position = Vector2.new(minX + w/2, minY - 18)
                            else
                                draws.Name.Visible = false
                            end

                            -- Health bar
                            if Config.ESP_Health then
                                local maxHP = hum.MaxHealth
                                local curHP = hum.Health
                                local ratio = math.clamp(curHP / maxHP, 0, 1)
                                local barH  = h * ratio
                                local barX  = minX - 8

                                draws.HealthBG.Visible  = true
                                draws.HealthBG.Position = Vector2.new(barX - 2, minY)
                                draws.HealthBG.Size     = Vector2.new(5, h)

                                draws.Health.Visible    = true
                                draws.Health.Color      = Color3.fromRGB(
                                    255 * (1 - ratio), 255 * ratio, 0)
                                draws.Health.Position   = Vector2.new(
                                    barX - 2, minY + (h - barH))
                                draws.Health.Size       = Vector2.new(5, barH)
                            else
                                draws.Health.Visible   = false
                                draws.HealthBG.Visible = false
                            end

                            -- Distance
                            if Config.ESP_Distance then
                                draws.Dist.Visible  = true
                                draws.Dist.Color    = Color3.fromRGB(200, 200, 200)
                                draws.Dist.Text     = string.format(
                                    "[%dm]", math.floor(worldDist))
                                draws.Dist.Position = Vector2.new(
                                    minX + w/2, maxY + 4)
                            else
                                draws.Dist.Visible = false
                            end

                            -- Tracer
                            if Config.ESP_Tracers then
                                local hrpSP = WorldToScreen(hrp.Position)
                                draws.Tracer.Visible = true
                                draws.Tracer.Color   = Config.ESP_TracerColor
                                draws.Tracer.From    = Vector2.new(
                                    ViewportCenter.X,
                                    Camera.ViewportSize.Y)
                                draws.Tracer.To = hrpSP
                            else
                                draws.Tracer.Visible = false
                            end
                        end
                    end
                end
            end
        end

        if not visible then
            for _, d in pairs(draws) do
                d.Visible = false
            end
        end
    end
end)

-- ══════════════════════════════════════════
--           RAYFIELD TABS
-- ══════════════════════════════════════════

local TabESP = Window:CreateTab("👁 ESP", 4483362458)
local TabAim = Window:CreateTab("🎯 Aimlock", 4483362458)
local TabCfg = Window:CreateTab("⚙️ Config", 4483362458)

-- ─── ESP Tab ────────────────────────────────────────────────────────

TabESP:CreateToggle({
    Name = "Enable ESP",
    CurrentValue = Config.ESP_Enabled,
    Callback = function(v) Config.ESP_Enabled = v end
})

TabESP:CreateToggle({
    Name = "Boxes",
    CurrentValue = Config.ESP_Boxes,
    Callback = function(v) Config.ESP_Boxes = v end
})

TabESP:CreateToggle({
    Name = "Names",
    CurrentValue = Config.ESP_Names,
    Callback = function(v) Config.ESP_Names = v end
})

TabESP:CreateToggle({
    Name = "Health Bar",
    CurrentValue = Config.ESP_Health,
    Callback = function(v) Config.ESP_Health = v end
})

TabESP:CreateToggle({
    Name = "Distance",
    CurrentValue = Config.ESP_Distance,
    Callback = function(v) Config.ESP_Distance = v end
})

TabESP:CreateToggle({
    Name = "Tracers",
    CurrentValue = Config.ESP_Tracers,
    Callback = function(v) Config.ESP_Tracers = v end
})

TabESP:CreateToggle({
    Name = "Team Check (enemies only)",
    CurrentValue = Config.ESP_TeamCheck,
    Callback = function(v)
        Config.ESP_TeamCheck = v
        Config.AIM_TeamCheck = v
    end
})

TabESP:CreateSlider({
    Name = "Max Distance (studs)",
    Range = {50, 2000},
    Increment = 50,
    CurrentValue = Config.ESP_MaxDist,
    Callback = function(v) Config.ESP_MaxDist = v end
})

TabESP:CreateColorPicker({
    Name = "Box Color",
    Color = Config.ESP_BoxColor,
    Callback = function(v) Config.ESP_BoxColor = v end
})

TabESP:CreateColorPicker({
    Name = "Tracer Color",
    Color = Config.ESP_TracerColor,
    Callback = function(v) Config.ESP_TracerColor = v end
})

-- ─── Aimlock Tab ────────────────────────────────────────────────────

TabAim:CreateToggle({
    Name = "Enable Aimlock",
    CurrentValue = Config.AIM_Enabled,
    Callback = function(v) Config.AIM_Enabled = v end
})

TabAim:CreateToggle({
    Name = "Show FOV Circle",
    CurrentValue = Config.AIM_ShowFOV,
    Callback = function(v) Config.AIM_ShowFOV = v end
})

TabAim:CreateSlider({
    Name = "FOV Radius (px)",
    Range = {20, 400},
    Increment = 5,
    CurrentValue = Config.AIM_FOV,
    Callback = function(v) Config.AIM_FOV = v end
})

TabAim:CreateSlider({
    Name = "Smoothness (lower = snappier)",
    Range = {1, 100},
    Increment = 1,
    CurrentValue = Config.AIM_Smoothness * 100,
    Callback = function(v) Config.AIM_Smoothness = v / 100 end
})

TabAim:CreateDropdown({
    Name = "Target Part",
    Options = {"Head", "HumanoidRootPart", "UpperTorso", "Torso"},
    CurrentOption = {Config.AIM_TargetPart},
    MultipleOptions = false,
    Callback = function(v) Config.AIM_TargetPart = v[1] or v end
})

TabAim:CreateKeybind({
    Name = "Hold Key (Aimlock)",
    CurrentKeybind = "Q",
    HoldToInteract = false,
    Callback = function(key)
        local ok, kc = pcall(function()
            return Enum.KeyCode[key]
        end)
        if ok and kc then
            UserInputService.InputBegan:Connect(function(input, gp)
                if gp then return end
                if input.KeyCode == kc then AimHeld = true end
            end)
            UserInputService.InputEnded:Connect(function(input)
                if input.KeyCode == kc then AimHeld = false end
            end)
        end
    end
})

-- ─── Config Tab ─────────────────────────────────────────────────────

TabCfg:CreateButton({
    Name = "Save Config",
    Callback = function()
        Rayfield:SaveConfiguration()
        Rayfield:Notify({
            Title = "Config",
            Content = "Saved ✔",
            Duration = 2
        })
    end
})

TabCfg:CreateButton({
    Name = "Destroy GUI",
    Callback = function()
        for player, _ in pairs(ESPObjects) do RemoveESP(player) end
        FOVCircle:Remove()
        Rayfield:Destroy()
    end
})

-- ══════════════════════════════════════════
--           INIT NOTIFY
-- ══════════════════════════════════════════

Rayfield:Notify({
    Title   = "NebulaX Loaded",
    Content = "ESP + Aimlock ready | RMB to aim",
    Duration = 4
})
