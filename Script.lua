-- ═══════════════════════════════════════════════════════
--  SPEEDHACK PRO v3 — ROBLOX EXECUTOR
--  Features: Humanoid-less movement | Smooth teleport | Anti-cheat bypass
-- ═══════════════════════════════════════════════════════

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- ═══════════════════════════════════════════════════════
--  CONFIGURATION
-- ═══════════════════════════════════════════════════════

local CONFIG = {
    MAX_SPEED = 1000,
    DEFAULT_SPEED = 16,
    TELEPORT_STEP = 0.05,
    SMOOTH_FACTOR = 0.3,
    FLY_HEIGHT_OFFSET = 2.5,
    GROUND_RAY_LENGTH = 10,
    COLLISION_CHECK_RADIUS = 2.5,
}

-- ═══════════════════════════════════════════════════════
--  STATE
-- ═══════════════════════════════════════════════════════

local State = {
    enabled = false,
    speed = CONFIG.DEFAULT_SPEED,
    humanoidRemoved = false,
    originalWalkSpeed = 16,
    connection = nil,
    lastPosition = nil,
    isFlying = false,
}

-- ═══════════════════════════════════════════════════════
--  UTILITY
-- ═══════════════════════════════════════════════════════

local function getCharacter()
    return LocalPlayer.Character
end

local function getRootPart()
    local char = getCharacter()
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function getHumanoid()
    local char = getCharacter()
    return char and char:FindFirstChildOfClass("Humanoid")
end

local function getGroundHeight(position)
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    raycastParams.FilterDescendantsInstances = {getCharacter()}
    
    local result = workspace:Raycast(
        position + Vector3.new(0, 50, 0),
        Vector3.new(0, -100, 0),
        raycastParams
    )
    
    if result then
        return result.Position.Y + CONFIG.FLY_HEIGHT_OFFSET
    end
    return position.Y
end

local function isPositionValid(position)
    local region = Region3.new(
        position - Vector3.new(CONFIG.COLLISION_CHECK_RADIUS, CONFIG.COLLISION_CHECK_RADIUS, CONFIG.COLLISION_CHECK_RADIUS),
        position + Vector3.new(CONFIG.COLLISION_CHECK_RADIUS, CONFIG.COLLISION_CHECK_RADIUS, CONFIG.COLLISION_CHECK_RADIUS)
    )
    
    local parts = workspace:FindPartsInRegion3(region, getCharacter(), 100)
    for _, part in ipairs(parts) do
        if part.CanCollide then
            return false
        end
    end
    return true
end

-- ═══════════════════════════════════════════════════════
--  ANTICHEAT BYPASS — REMOVE HUMANOID
-- ═══════════════════════════════════════════════════════

local function removeHumanoid()
    local char = getCharacter()
    if not char then return end
    
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if not humanoid then
        State.humanoidRemoved = true
        return
    end
    
    State.originalWalkSpeed = humanoid.WalkSpeed
    humanoid:Destroy()
    
    local rootPart = char:FindFirstChild("HumanoidRootPart")
    if rootPart then
        rootPart.Anchored = false
        rootPart.CanCollide = true
    end
    
    State.humanoidRemoved = true
end

local function restoreHumanoid()
    local char = getCharacter()
    if not char then return end
    if char:FindFirstChildOfClass("Humanoid") then return end
    
    local humanoid = Instance.new("Humanoid")
    humanoid.Name = "Humanoid"
    humanoid.WalkSpeed = State.originalWalkSpeed
    humanoid.JumpPower = 50
    humanoid.Parent = char
    
    State.humanoidRemoved = false
end

-- ═══════════════════════════════════════════════════════
--  CAMERA CONTROL (works without Humanoid)
-- ═══════════════════════════════════════════════════════

local function setupCamera()
    local char = getCharacter()
    if char then
        local head = char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart")
        if head then
            Camera.CameraSubject = head
        end
    end
end

-- ═══════════════════════════════════════════════════════
--  MOVEMENT ENGINE — SMOOTH TELEPORT
-- ═══════════════════════════════════════════════════════

local function calculateMovementDirection()
    local moveDirection = Vector3.zero
    local forward = 0
    local right = 0
    
    if UserInputService:IsKeyDown(Enum.KeyCode.W) then forward = forward + 1 end
    if UserInputService:IsKeyDown(Enum.KeyCode.S) then forward = forward - 1 end
    if UserInputService:IsKeyDown(Enum.KeyCode.A) then right = right - 1 end
    if UserInputService:IsKeyDown(Enum.KeyCode.D) then right = right + 1 end
    
    if forward == 0 and right == 0 then
        return Vector3.zero
    end
    
    local cameraLook = Camera.CFrame.LookVector
    local cameraRight = Camera.CFrame.RightVector
    
    local flatLook = Vector3.new(cameraLook.X, 0, cameraLook.Z).Unit
    local flatRight = Vector3.new(cameraRight.X, 0, cameraRight.Z).Unit
    
    moveDirection = (flatLook * forward + flatRight * right)
    
    if moveDirection.Magnitude > 0 then
        moveDirection = moveDirection.Unit
    end
    
    return moveDirection
end

local function smoothTeleportMovement()
    if not State.enabled then return end
    
    local rootPart = getRootPart()
    if not rootPart then return end
    
    local moveDirection = calculateMovementDirection()
    
    if moveDirection.Magnitude < 0.1 then
        State.lastPosition = rootPart.Position
        return
    end
    
    local deltaTime = CONFIG.TELEPORT_STEP
    local speed = math.clamp(State.speed, 1, CONFIG.MAX_SPEED)
    local stepDistance = speed * deltaTime
    
    local currentPos = rootPart.Position
    local newPos = currentPos + (moveDirection * stepDistance)
    
    if not State.isFlying then
        local groundY = getGroundHeight(newPos)
        newPos = Vector3.new(newPos.X, groundY, newPos.Z)
    end
    
    if not isPositionValid(newPos) then
        local slidePos = Vector3.new(currentPos.X, newPos.Y, newPos.Z)
        if isPositionValid(slidePos) then
            newPos = slidePos
        else
            slidePos = Vector3.new(newPos.X, newPos.Y, currentPos.Z)
            if isPositionValid(slidePos) then
                newPos = slidePos
            else
                return
            end
        end
    end
    
    local currentCFrame = rootPart.CFrame
    local newCFrame = CFrame.new(newPos) * CFrame.Angles(0, math.atan2(moveDirection.X, moveDirection.Z), 0)
    local smoothCFrame = currentCFrame:Lerp(newCFrame, CONFIG.SMOOTH_FACTOR)
    
    rootPart.CFrame = smoothCFrame
    rootPart.Velocity = Vector3.zero
    
    State.lastPosition = newPos
    setupCamera()
end

-- ═══════════════════════════════════════════════════════
--  MAIN LOOP
-- ═══════════════════════════════════════════════════════

local function startSpeedHack()
    if State.connection then return end
    removeHumanoid()
    setupCamera()
    State.enabled = true
    State.lastPosition = getRootPart() and getRootPart().Position
    
    State.connection = RunService.Heartbeat:Connect(function()
        smoothTeleportMovement()
    end)
end

local function stopSpeedHack()
    State.enabled = false
    if State.connection then
        State.connection:Disconnect()
        State.connection = nil
    end
    restoreHumanoid()
end

-- ═══════════════════════════════════════════════════════
--  GUI — DARK MODERN UI
-- ═══════════════════════════════════════════════════════

local function createGUI()
    local existing = CoreGui:FindFirstChild("SpeedHackPro")
    if existing then existing:Destroy() end
    
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "SpeedHackPro"
    ScreenGui.Parent = CoreGui
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.ResetOnSpawn = false
    
    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Size = UDim2.new(0, 320, 0, 420)
    MainFrame.Position = UDim2.new(0.5, -160, 0.5, -210)
    MainFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
    MainFrame.BorderSizePixel = 0
    MainFrame.Parent = ScreenGui
    
    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 12)
    Corner.Parent = MainFrame
    
    local Shadow = Instance.new("ImageLabel")
    Shadow.Name = "Shadow"
    Shadow.Size = UDim2.new(1, 40, 1, 40)
    Shadow.Position = UDim2.new(0, -20, 0, -20)
    Shadow.BackgroundTransparency = 1
    Shadow.Image = "rbxassetid://5554236805"
    Shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
    Shadow.ImageTransparency = 0.6
    Shadow.ScaleType = Enum.ScaleType.Slice
    Shadow.SliceCenter = Rect.new(23, 23, 277, 277)
    Shadow.Parent = MainFrame
    
    local TitleBar = Instance.new("Frame")
    TitleBar.Name = "TitleBar"
    TitleBar.Size = UDim2.new(1, 0, 0, 45)
    TitleBar.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    TitleBar.BorderSizePixel = 0
    TitleBar.Parent = MainFrame
    
    local TitleCorner = Instance.new("UICorner")
    TitleCorner.CornerRadius = UDim.new(0, 12)
    TitleCorner.Parent = TitleBar
    
    local TitleText = Instance.new("TextLabel")
    TitleText.Name = "Title"
    TitleText.Size = UDim2.new(1, -50, 1, 0)
    TitleText.Position = UDim2.new(0, 15, 0, 0)
    TitleText.BackgroundTransparency = 1
    TitleText.Text = "SPEEDHACK PRO v3"
    TitleText.TextColor3 = Color3.fromRGB(0, 200, 255)
    TitleText.TextSize = 16
    TitleText.Font = Enum.Font.GothamBold
    TitleText.TextXAlignment = Enum.TextXAlignment.Left
    TitleText.Parent = TitleBar
    
    local CloseBtn = Instance.new("TextButton")
    CloseBtn.Name = "Close"
    CloseBtn.Size = UDim2.new(0, 30, 0, 30)
    CloseBtn.Position = UDim2.new(1, -38, 0, 8)
    CloseBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    CloseBtn.Text = "×"
    CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    CloseBtn.TextSize = 20
    CloseBtn.Font = Enum.Font.GothamBold
    CloseBtn.Parent = TitleBar
    
    local CloseCorner = Instance.new("UICorner")
    CloseCorner.CornerRadius = UDim.new(0, 6)
    CloseCorner.Parent = CloseBtn
    
    local MinimizeBtn = Instance.new("TextButton")
    MinimizeBtn.Name = "Minimize"
    MinimizeBtn.Size = UDim2.new(0, 30, 0, 30)
    MinimizeBtn.Position = UDim2.new(1, -72, 0, 8)
    MinimizeBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 65)
    MinimizeBtn.Text = "−"
    MinimizeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    MinimizeBtn.TextSize = 20
    MinimizeBtn.Font = Enum.Font.GothamBold
    MinimizeBtn.Parent = TitleBar
    
    local MinimizeCorner = Instance.new("UICorner")
    MinimizeCorner.CornerRadius = UDim.new(0, 6)
    MinimizeCorner.Parent = MinimizeBtn
    
    local Content = Instance.new("Frame")
    Content.Name = "Content"
    Content.Size = UDim2.new(1, -20, 1, -55)
    Content.Position = UDim2.new(0, 10, 0, 50)
    Content.BackgroundTransparency = 1
    Content.Parent = MainFrame
    
    -- TOGGLE SECTION
    local ToggleSection = Instance.new("Frame")
    ToggleSection.Name = "ToggleSection"
    ToggleSection.Size = UDim2.new(1, 0, 0, 60)
    ToggleSection.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    ToggleSection.BorderSizePixel = 0
    ToggleSection.Parent = Content
    
    local ToggleCorner = Instance.new("UICorner")
    ToggleCorner.CornerRadius = UDim.new(0, 8)
    ToggleCorner.Parent = ToggleSection
    
    local ToggleLabel = Instance.new("TextLabel")
    ToggleLabel.Size = UDim2.new(0.6, 0, 1, 0)
    ToggleLabel.Position = UDim2.new(0, 12, 0, 0)
    ToggleLabel.BackgroundTransparency = 1
    ToggleLabel.Text = "SpeedHack"
    ToggleLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
    ToggleLabel.TextSize = 14
    ToggleLabel.Font = Enum.Font.GothamSemibold
    ToggleLabel.TextXAlignment = Enum.TextXAlignment.Left
    ToggleLabel.Parent = ToggleSection
    
    local ToggleSwitch = Instance.new("Frame")
    ToggleSwitch.Name = "ToggleSwitch"
    ToggleSwitch.Size = UDim2.new(0, 50, 0, 26)
    ToggleSwitch.Position = UDim2.new(1, -62, 0.5, -13)
    ToggleSwitch.BackgroundColor3 = Color3.fromRGB(60, 60, 65)
    ToggleSwitch.BorderSizePixel = 0
    ToggleSwitch.Parent = ToggleSection
    
    local SwitchCorner = Instance.new("UICorner")
    SwitchCorner.CornerRadius = UDim.new(1, 0)
    SwitchCorner.Parent = ToggleSwitch
    
    local ToggleKnob = Instance.new("Frame")
    ToggleKnob.Name = "Knob"
    ToggleKnob.Size = UDim2.new(0, 22, 0, 22)
    ToggleKnob.Position = UDim2.new(0, 2, 0.5, -11)
    ToggleKnob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    ToggleKnob.BorderSizePixel = 0
    ToggleKnob.Parent = ToggleSwitch
    
    local KnobCorner = Instance.new("UICorner")
    KnobCorner.CornerRadius = UDim.new(1, 0)
    KnobCorner.Parent = ToggleKnob
    
    local ToggleBtn = Instance.new("TextButton")
    ToggleBtn.Size = UDim2.new(1, 0, 1, 0)
    ToggleBtn.BackgroundTransparency = 1
    ToggleBtn.Text = ""
    ToggleBtn.Parent = ToggleSwitch
    
    local StatusText = Instance.new("TextLabel")
    StatusText.Name = "Status"
    StatusText.Size = UDim2.new(1, 0, 0, 20)
    StatusText.Position = UDim2.new(0, 0, 0, 65)
    StatusText.BackgroundTransparency = 1
    StatusText.Text = "Status: OFF"
    StatusText.TextColor3 = Color3.fromRGB(150, 150, 150)
    StatusText.TextSize = 12
    StatusText.Font = Enum.Font.Gotham
    StatusText.TextXAlignment = Enum.TextXAlignment.Center
    StatusText.Parent = Content
    
    -- SPEED SLIDER
    local SpeedSection = Instance.new("Frame")
    SpeedSection.Name = "SpeedSection"
    SpeedSection.Size = UDim2.new(1, 0, 0, 80)
    SpeedSection.Position = UDim2.new(0, 0, 0, 90)
    SpeedSection.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    SpeedSection.BorderSizePixel = 0
    SpeedSection.Parent = Content
    
    local SpeedCorner = Instance.new("UICorner")
    SpeedCorner.CornerRadius = UDim.new(0, 8)
    SpeedCorner.Parent = SpeedSection
    
    local SpeedLabel = Instance.new("TextLabel")
    SpeedLabel.Size = UDim2.new(0.5, 0, 0, 25)
    SpeedLabel.Position = UDim2.new(0, 12, 0, 8)
    SpeedLabel.BackgroundTransparency = 1
    SpeedLabel.Text = "Speed"
    SpeedLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
    SpeedLabel.TextSize = 14
    SpeedLabel.Font = Enum.Font.GothamSemibold
    SpeedLabel.TextXAlignment = Enum.TextXAlignment.Left
    SpeedLabel.Parent = SpeedSection
    
    local SpeedValue = Instance.new("TextLabel")
    SpeedValue.Size = UDim2.new(0.4, 0, 0, 25)
    SpeedValue.Position = UDim2.new(0.55, 0, 0, 8)
    SpeedValue.BackgroundTransparency = 1
    SpeedValue.Text = "16"
    SpeedValue.TextColor3 = Color3.fromRGB(0, 200, 255)
    SpeedValue.TextSize = 14
    SpeedValue.Font = Enum.Font.GothamBold
    SpeedValue.TextXAlignment = Enum.TextXAlignment.Right
    SpeedValue.Parent = SpeedSection
    
    local SliderBg = Instance.new("Frame")
    SliderBg.Name = "SliderBg"
    SliderBg.Size = UDim2.new(1, -24, 0, 8)
    SliderBg.Position = UDim2.new(0, 12, 0, 45)
    SliderBg.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
    SliderBg.BorderSizePixel = 0
    SliderBg.Parent = SpeedSection
    
    local SliderBgCorner = Instance.new("UICorner")
    SliderBgCorner.CornerRadius = UDim.new(1, 0)
    SliderBgCorner.Parent = SliderBg
    
    local SliderFill = Instance.new("Frame")
    SliderFill.Name = "SliderFill"
    SliderFill.Size = UDim2.new(0.015, 0, 1, 0)
    SliderFill.BackgroundColor3 = Color3.fromRGB(0, 200, 255)
    SliderFill.BorderSizePixel = 0
    SliderFill.Parent = SliderBg
    
    local SliderFillCorner = Instance.new("UICorner")
    SliderFillCorner.CornerRadius = UDim.new(1, 0)
    SliderFillCorner.Parent = SliderFill
    
    local SliderKnob = Instance.new("Frame")
    SliderKnob.Name = "SliderKnob"
    SliderKnob.Size = UDim2.new(0, 16, 0, 16)
    SliderKnob.Position = UDim2.new(0.015, -8, 0.5, -8)
    SliderKnob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    SliderKnob.BorderSizePixel = 0
    SliderKnob.Parent = SliderBg
    
    local SliderKnobCorner = Instance.new("UICorner")
    SliderKnobCorner.CornerRadius = UDim.new(1, 0)
    SliderKnobCorner.Parent = SliderKnob
    
    local SliderBtn = Instance.new("TextButton")
    SliderBtn.Size = UDim2.new(1, 0, 1, 0)
    SliderBtn.BackgroundTransparency = 1
    SliderBtn.Text = ""
    SliderBtn.Parent = SliderBg
    
    local SpeedInput = Instance.new("TextBox")
    SpeedInput.Size = UDim2.new(0, 60, 0, 25)
    SpeedInput.Position = UDim2.new(1, -72, 0, 8)
    SpeedInput.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
    SpeedInput.Text = "16"
    SpeedInput.TextColor3 = Color3.fromRGB(0, 200, 255)
    SpeedInput.TextSize = 13
    SpeedInput.Font = Enum.Font.GothamBold
    SpeedInput.ClearTextOnFocus = true
    SpeedInput.Parent = SpeedSection
    
    local SpeedInputCorner = Instance.new("UICorner")
    SpeedInputCorner.CornerRadius = UDim.new(0, 4)
    SpeedInputCorner.Parent = SpeedInput
    
    -- BYPASS SECTION
    local BypassSection = Instance.new("Frame")
    BypassSection.Name = "BypassSection"
    BypassSection.Size = UDim2.new(1, 0, 0, 60)
    BypassSection.Position = UDim2.new(0, 0, 0, 180)
    BypassSection.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    BypassSection.BorderSizePixel = 0
    BypassSection.Parent = Content
    
    local BypassCorner = Instance.new("UICorner")
    BypassCorner.CornerRadius = UDim.new(0, 8)
    BypassCorner.Parent = BypassSection
    
    local BypassLabel = Instance.new("TextLabel")
    BypassLabel.Size = UDim2.new(0.6, 0, 1, 0)
    BypassLabel.Position = UDim2.new(0, 12, 0, 0)
    BypassLabel.BackgroundTransparency = 1
    BypassLabel.Text = "AntiCheat Bypass"
    BypassLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
    BypassLabel.TextSize = 14
    BypassLabel.Font = Enum.Font.GothamSemibold
    BypassLabel.TextXAlignment = Enum.TextXAlignment.Left
    BypassLabel.Parent = BypassSection
    
    local BypassStatus = Instance.new("TextLabel")
    BypassStatus.Size = UDim2.new(0.35, 0, 1, 0)
    BypassStatus.Position = UDim2.new(0.6, 0, 0, 0)
    BypassStatus.BackgroundTransparency = 1
    BypassStatus.Text = "Active"
    BypassStatus.TextColor3 = Color3.fromRGB(0, 255, 100)
    BypassStatus.TextSize = 12
    BypassStatus.Font = Enum.Font.GothamBold
    BypassStatus.TextXAlignment = Enum.TextXAlignment.Right
    BypassStatus.Parent = BypassSection
    
    -- FLY MODE
    local FlySection = Instance.new("Frame")
    FlySection.Name = "FlySection"
    FlySection.Size = UDim2.new(1, 0, 0, 60)
    FlySection.Position = UDim2.new(0, 0, 0, 248)
    FlySection.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    FlySection.BorderSizePixel = 0
    FlySection.Parent = Content
    
    local FlyCorner = Instance.new("UICorner")
    FlyCorner.CornerRadius = UDim.new(0, 8)
    FlyCorner.Parent = FlySection
    
    local FlyLabel = Instance.new("TextLabel")
    FlyLabel.Size = UDim2.new(0.6, 0, 1, 0)
    FlyLabel.Position = UDim2.new(0, 12, 0, 0)
    FlyLabel.BackgroundTransparency = 1
    FlyLabel.Text = "Fly Mode (NoClip)"
    FlyLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
    FlyLabel.TextSize = 14
    FlyLabel.Font = Enum.Font.GothamSemibold
    FlyLabel.TextXAlignment = Enum.TextXAlignment.Left
    FlyLabel.Parent = FlySection
    
    local FlySwitch = Instance.new("Frame")
    FlySwitch.Name = "FlySwitch"
    FlySwitch.Size = UDim2.new(0, 50, 0, 26)
    FlySwitch.Position = UDim2.new(1, -62, 0.5, -13)
    FlySwitch.BackgroundColor3 = Color3.fromRGB(60, 60, 65)
    FlySwitch.BorderSizePixel = 0
    FlySwitch.Parent = FlySection
    
    local FlySwitchCorner = Instance.new("UICorner")
    FlySwitchCorner.CornerRadius = UDim.new(1, 0)
    FlySwitchCorner.Parent = FlySwitch
    
    local FlyKnob = Instance.new("Frame")
    FlyKnob.Name = "Knob"
    FlyKnob.Size = UDim2.new(0, 22, 0, 22)
    FlyKnob.Position = UDim2.new(0, 2, 0.5, -11)
    FlyKnob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    FlyKnob.BorderSizePixel = 0
    FlyKnob.Parent = FlySwitch
    
    local FlyKnobCorner = Instance.new("UICorner")
    FlyKnobCorner.CornerRadius = UDim.new(1, 0)
    FlyKnobCorner.Parent = FlyKnob
    
    local FlyBtn = Instance.new("TextButton")
    FlyBtn.Size = UDim2.new(1, 0, 1, 0)
    FlyBtn.BackgroundTransparency = 1
    FlyBtn.Text = ""
    FlyBtn.Parent = FlySwitch
    
    -- INFO SECTION
    local InfoSection = Instance.new("Frame")
    InfoSection.Name = "InfoSection"
    InfoSection.Size = UDim2.new(1, 0, 0, 70)
    InfoSection.Position = UDim2.new(0, 0, 0, 318)
    InfoSection.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    InfoSection.BorderSizePixel = 0
    InfoSection.Parent = Content
    
    local InfoCorner = Instance.new("UICorner")
    InfoCorner.CornerRadius = UDim.new(0, 8)
    InfoCorner.Parent = InfoSection
    
    local InfoText = Instance.new("TextLabel")
    InfoText.Size = UDim2.new(1, -16, 1, -10)
    InfoText.Position = UDim2.new(0, 8, 0, 5)
    InfoText.BackgroundTransparency = 1
    InfoText.Text = "WASD to move\nHumanoid removed — anti-cheat bypass active\nCamera preserved"
    InfoText.TextColor3 = Color3.fromRGB(150, 150, 150)
    InfoText.TextSize = 11
    InfoText.Font = Enum.Font.Gotham
    InfoText.TextWrapped = true
    InfoText.TextYAlignment = Enum.TextYAlignment.Center
    InfoText.Parent = InfoSection
    
    -- VISUAL UPDATES
    local function updateToggleVisual(enabled)
        if enabled then
            TweenService:Create(ToggleSwitch, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(0, 200, 255)}):Play()
            TweenService:Create(ToggleKnob, TweenInfo.new(0.2), {Position = UDim2.new(0, 26, 0.5, -11)}):Play()
            StatusText.Text = "Status: ON | Speed: " .. tostring(State.speed)
            StatusText.TextColor3 = Color3.fromRGB(0, 255, 100)
        else
            TweenService:Create(ToggleSwitch, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(60, 60, 65)}):Play()
            TweenService:Create(ToggleKnob, TweenInfo.new(0.2), {Position = UDim2.new(0, 2, 0.5, -11)}):Play()
            StatusText.Text = "Status: OFF"
            StatusText.TextColor3 = Color3.fromRGB(150, 150, 150)
        end
    end
    
    local function updateFlyVisual(enabled)
        if enabled then
            TweenService:Create(FlySwitch, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(255, 150, 0)}):Play()
            TweenService:Create(FlyKnob, TweenInfo.new(0.2), {Position = UDim2.new(0, 26, 0.5, -11)}):Play()
        else
            TweenService:Create(FlySwitch, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(60, 60, 65)}):Play()
            TweenService:Create(FlyKnob, TweenInfo.new(0.2), {Position = UDim2.new(0, 2, 0.5, -11)}):Play()
        end
    end
    
    local function updateSpeedVisual(speed)
        local ratio = (speed - 1) / (CONFIG.MAX_SPEED - 1)
        ratio = math.clamp(ratio, 0, 1)
        
        TweenService:Create(SliderFill, TweenInfo.new(0.1), {Size = UDim2.new(ratio, 0, 1, 0)}):Play()
        TweenService:Create(SliderKnob, TweenInfo.new(0.1), {Position = UDim2.new(ratio, -8, 0.5, -8)}):Play()
        
        SpeedValue.Text = tostring(math.floor(speed))
        SpeedInput.Text = tostring(math.floor(speed))
        
        if State.enabled then
            StatusText.Text = "Status: ON | Speed: " .. tostring(math.floor(speed))
        end
    end
    
    -- EVENTS
    ToggleBtn.MouseButton1Click:Connect(function()
        if State.enabled then
            stopSpeedHack()
        else
            startSpeedHack()
        end
        updateToggleVisual(State.enabled)
    end)
    
    local dragging = false
    
    local function setSpeedFromPosition(x)
        local sliderStart = SliderBg.AbsolutePosition.X
        local sliderWidth = SliderBg.AbsoluteSize.X
        local ratio = math.clamp((x - sliderStart) / sliderWidth, 0, 1)
        local speed = 1 + ratio * (CONFIG.MAX_SPEED - 1)
        State.speed = math.floor(speed)
        updateSpeedVisual(State.speed)
    end
    
    SliderBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            setSpeedFromPosition(input.Position.X)
        end
    end)
    
    SliderBtn.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            setSpeedFromPosition(input.Position.X)
        end
    end)
    
    SpeedInput.FocusLost:Connect(function()
        local num = tonumber(SpeedInput.Text)
        if num then
            num = math.clamp(math.floor(num), 1, CONFIG.MAX_SPEED)
            State.speed = num
            updateSpeedVisual(num)
        else
            SpeedInput.Text = tostring(State.speed)
        end
    end)
    
    FlyBtn.MouseButton1Click:Connect(function()
        State.isFlying = not State.isFlying
        updateFlyVisual(State.isFlying)
    end)
    
    CloseBtn.MouseButton1Click:Connect(function()
        if State.enabled then
            stopSpeedHack()
        end
        ScreenGui:Destroy()
    end)
    
    local minimized = false
    MinimizeBtn.MouseButton1Click:Connect(function()
        minimized = not minimized
        if minimized then
            TweenService:Create(Content, TweenInfo.new(0.3), {Size = UDim2.new(1, -20, 0, 0)}):Play()
            TweenService:Create(MainFrame, TweenInfo.new(0.3), {Size = UDim2.new(0, 320, 0, 45)}):Play()
        else
            TweenService:Create(Content, TweenInfo.new(0.3), {Size = UDim2.new(1, -20, 1, -55)}):Play()
            TweenService:Create(MainFrame, TweenInfo.new(0.3), {Size = UDim2.new(0, 320, 0, 420)}):Play()
        end
    end)
    
    -- DRAGGING
    local dragStart, startPos
    
    TitleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragStart = input.Position
            startPos = MainFrame.Position
        end
    end)
    
    TitleBar.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement and dragStart then
            local delta = input.Position - dragStart
            MainFrame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
    
    TitleBar.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragStart = nil
        end
    end)
    
    -- RESPAWN HANDLER
    LocalPlayer.CharacterAdded:Connect(function()
        wait(0.5)
        if State.enabled then
            removeHumanoid()
            setupCamera()
            State.lastPosition = getRootPart() and getRootPart().Position
        end
    end)
    
    updateSpeedVisual(State.speed)
    updateToggleVisual(false)
    updateFlyVisual(false)
    
    return ScreenGui
end

-- ═══════════════════════════════════════════════════════
--  INITIALIZE
-- ═══════════════════════════════════════════════════════

createGUI()

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed and input.KeyCode == Enum.KeyCode.RightShift then
        local mainGui = CoreGui:FindFirstChild("SpeedHackPro")
        if mainGui then
            mainGui.Enabled = not mainGui.Enabled
        end
    end
end)

print("[SPEEDHACK PRO] Loaded. Press RightShift to toggle GUI.")
