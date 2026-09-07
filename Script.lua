--[[
    diox616 × Nyx Speed — Unified PC + Mobile Edition (FIXED)
    Fixes: ScreenSizeDpi crash, Heartbeat yielding, ScreenOrientation error, parentGui handling
]]--

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local Camera = Workspace.CurrentCamera

-- // Mobile detection (FIXED: removed ScreenSizeDpi which doesn't exist and crashes)
local IS_MOBILE = UserInputService.TouchEnabled and not UserInputService.MouseEnabled

-- // Responsive sizing
local UI_SCALE = IS_MOBILE and 0.82 or 1.0
local MAIN_W = math.floor(680 * UI_SCALE)
local MAIN_H = math.floor(440 * UI_SCALE)
local SIDEBAR_W = math.floor(175 * UI_SCALE)

local connections = {}

-- // Parent GUI (FIXED: more robust detection)
local parentGui = CoreGui
pcall(function()
    if type(gethui) == "function" then
        local hui = gethui()
        if hui and typeof(hui) == "Instance" then
            parentGui = hui
        end
    end
end)
-- Verify we can actually parent to it
local canParent = pcall(function()
    local test = Instance.new("Frame")
    test.Name = "__parentTest"
    test.Parent = parentGui
    test:Destroy()
end)
if not canParent then
    parentGui = PlayerGui
end

-- Clean old instances
local oldGui = parentGui:FindFirstChild("diox616NyxGui")
if oldGui then oldGui:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "diox616NyxGui"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
-- FIXED: wrap ScreenOrientation in pcall (not supported on all platforms)
pcall(function()
    ScreenGui.ScreenOrientation = Enum.ScreenOrientation.Sensor
end)
ScreenGui.Parent = parentGui

print("[diox616 × Nyx] GUI parented to:", parentGui.Name)

-- ==========================================
-- Notification System
-- ==========================================
local NotificationContainer = Instance.new("Frame")
NotificationContainer.Name = "NotificationContainer"
NotificationContainer.Size = UDim2.new(0, IS_MOBILE and 260 or 300, 1, -40)
NotificationContainer.Position = UDim2.new(1, IS_MOBILE and -280 or -320, 0, 20)
NotificationContainer.BackgroundTransparency = 1
NotificationContainer.Parent = ScreenGui

local UIListLayout_Notif = Instance.new("UIListLayout")
UIListLayout_Notif.HorizontalAlignment = Enum.HorizontalAlignment.Right
UIListLayout_Notif.VerticalAlignment = Enum.VerticalAlignment.Bottom
UIListLayout_Notif.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout_Notif.Padding = UDim.new(0, 10)
UIListLayout_Notif.Parent = NotificationContainer

local function Notify(title, message, duration)
    duration = duration or 3
    
    local NotifFrame = Instance.new("Frame")
    NotifFrame.Size = UDim2.new(0, IS_MOBILE and 260 or 300, 0, 65)
    NotifFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    NotifFrame.BackgroundTransparency = 1
    NotifFrame.BorderSizePixel = 0
    NotifFrame.Position = UDim2.new(1, 40, 0, 0)
    
    local UICorner = Instance.new("UICorner")
    UICorner.CornerRadius = UDim.new(0, 10)
    UICorner.Parent = NotifFrame
    
    local UIStroke = Instance.new("UIStroke")
    UIStroke.Color = Color3.fromRGB(120, 80, 200)
    UIStroke.Transparency = 1
    UIStroke.Thickness = 1.5
    UIStroke.Parent = NotifFrame
    
    local AccentLine = Instance.new("Frame")
    AccentLine.Size = UDim2.new(0, 3, 1, -16)
    AccentLine.Position = UDim2.new(0, 8, 0, 8)
    AccentLine.BackgroundColor3 = Color3.fromRGB(120, 80, 200)
    AccentLine.BorderSizePixel = 0
    AccentLine.BackgroundTransparency = 1
    
    local AccentCorner = Instance.new("UICorner")
    AccentCorner.CornerRadius = UDim.new(1, 0)
    AccentCorner.Parent = AccentLine
    AccentLine.Parent = NotifFrame
    
    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Size = UDim2.new(1, -30, 0, 20)
    TitleLabel.Position = UDim2.new(0, 22, 0, 10)
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Font = Enum.Font.GothamBold
    TitleLabel.Text = title
    TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    TitleLabel.TextSize = IS_MOBILE and 14 or 13
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    TitleLabel.TextTransparency = 1
    TitleLabel.Parent = NotifFrame
    
    local DescLabel = Instance.new("TextLabel")
    DescLabel.Size = UDim2.new(1, -30, 0, 20)
    DescLabel.Position = UDim2.new(0, 22, 0, 30)
    DescLabel.BackgroundTransparency = 1
    DescLabel.Font = Enum.Font.Gotham
    DescLabel.Text = message
    DescLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    DescLabel.TextSize = IS_MOBILE and 13 or 12
    DescLabel.TextXAlignment = Enum.TextXAlignment.Left
    DescLabel.TextTransparency = 1
    DescLabel.Parent = NotifFrame
    
    NotifFrame.Parent = NotificationContainer
    
    TweenService:Create(NotifFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {BackgroundTransparency = 0.05, Position = UDim2.new(0, 0, 0, 0)}):Play()
    TweenService:Create(UIStroke, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Transparency = 0.4}):Play()
    TweenService:Create(AccentLine, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {BackgroundTransparency = 0}):Play()
    TweenService:Create(TitleLabel, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {TextTransparency = 0}):Play()
    TweenService:Create(DescLabel, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {TextTransparency = 0}):Play()
    
    task.delay(duration, function()
        if NotifFrame and NotifFrame.Parent then
            local tweenOut = TweenService:Create(NotifFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {BackgroundTransparency = 1, Position = UDim2.new(1, 40, 0, 0)})
            TweenService:Create(UIStroke, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {Transparency = 1}):Play()
            TweenService:Create(AccentLine, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {BackgroundTransparency = 1}):Play()
            TweenService:Create(TitleLabel, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {TextTransparency = 1}):Play()
            TweenService:Create(DescLabel, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {TextTransparency = 1}):Play()
            tweenOut:Play()
            tweenOut.Completed:Connect(function()
                NotifFrame:Destroy()
            end)
        end
    end)
end

-- ==========================================
-- Proximity Prompt Hook
-- ==========================================
local function HookPrompt(prompt)
    if prompt:IsA("ProximityPrompt") then
        prompt.HoldDuration = 0
        prompt.MaxActivationDistance = 50
    end
end

for _, descendant in ipairs(Workspace:GetDescendants()) do
    HookPrompt(descendant)
end

table.insert(connections, Workspace.DescendantAdded:Connect(function(descendant)
    HookPrompt(descendant)
end))

-- ==========================================
-- Main Window Frame
-- ==========================================
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, MAIN_W, 0, MAIN_H)
MainFrame.Position = UDim2.new(0.5, -MAIN_W/2, 0.5, -MAIN_H/2)
MainFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
MainFrame.BackgroundTransparency = 1
MainFrame.BorderSizePixel = 0
MainFrame.ClipsDescendants = true
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 12)
MainCorner.Parent = MainFrame

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Color3.fromRGB(120, 80, 200)
MainStroke.Transparency = 1
MainStroke.Thickness = 1.5
MainStroke.Parent = MainFrame

local TopBar = Instance.new("Frame")
TopBar.Name = "TopBar"
TopBar.Size = UDim2.new(1, 0, 0, IS_MOBILE and 60 or 55)
TopBar.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
TopBar.BackgroundTransparency = 1
TopBar.BorderSizePixel = 0
TopBar.Parent = MainFrame

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Name = "TitleLabel"
TitleLabel.Size = UDim2.new(0, 250, 0, 22)
TitleLabel.Position = UDim2.new(0, 20, 0, IS_MOBILE and 14 or 10)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.Text = "diox616 × Nyx"
TitleLabel.TextColor3 = Color3.fromRGB(180, 140, 255)
TitleLabel.TextSize = IS_MOBILE and 20 or 18
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.TextTransparency = 1
TitleLabel.Parent = TopBar

local SubtitleLabel = Instance.new("TextLabel")
SubtitleLabel.Name = "SubtitleLabel"
SubtitleLabel.Size = UDim2.new(0, 250, 0, 15)
SubtitleLabel.Position = UDim2.new(0, 20, 0, IS_MOBILE and 36 or 30)
SubtitleLabel.BackgroundTransparency = 1
SubtitleLabel.Font = Enum.Font.GothamMedium
SubtitleLabel.Text = IS_MOBILE and "PC + Mobile Edition" or "Premium Interface — Unified"
SubtitleLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
SubtitleLabel.TextSize = IS_MOBILE and 13 or 11
SubtitleLabel.TextXAlignment = Enum.TextXAlignment.Left
SubtitleLabel.TextTransparency = 1
SubtitleLabel.Parent = TopBar

local CloseButton = Instance.new("TextButton")
CloseButton.Name = "CloseButton"
CloseButton.Size = UDim2.new(0, IS_MOBILE and 40 or 30, 0, IS_MOBILE and 40 or 30)
CloseButton.Position = UDim2.new(1, IS_MOBILE and -50 or -40, 0, IS_MOBILE and 10 or 12)
CloseButton.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
CloseButton.BackgroundTransparency = 1
CloseButton.AutoButtonColor = false
CloseButton.Font = Enum.Font.GothamBold
CloseButton.Text = "×"
CloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseButton.TextSize = IS_MOBILE and 22 or 18
CloseButton.Parent = TopBar

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 6)
CloseCorner.Parent = CloseButton

CloseButton.MouseEnter:Connect(function()
    if not IS_MOBILE then
        TweenService:Create(CloseButton, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(200, 50, 50), TextColor3 = Color3.fromRGB(255, 255, 255), BackgroundTransparency = 0}):Play()
    end
end)
CloseButton.MouseLeave:Connect(function()
    if not IS_MOBILE then
        TweenService:Create(CloseButton, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(20, 20, 20), TextColor3 = Color3.fromRGB(255, 255, 255), BackgroundTransparency = 1}):Play()
    end
end)

CloseButton.MouseButton1Click:Connect(function()
    local twClose = TweenService:Create(MainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {BackgroundTransparency = 1})
    TweenService:Create(MainStroke, TweenInfo.new(0.3), {Transparency = 1}):Play()
    twClose:Play()
    twClose.Completed:Connect(function()
        ScreenGui:Destroy()
    end)
end)

local HeaderDivider = Instance.new("Frame")
HeaderDivider.Name = "HeaderDivider"
HeaderDivider.Size = UDim2.new(1, 0, 0, 1)
HeaderDivider.Position = UDim2.new(0, 0, 0, IS_MOBILE and 60 or 55)
HeaderDivider.BackgroundColor3 = Color3.fromRGB(120, 80, 200)
HeaderDivider.BorderSizePixel = 0
HeaderDivider.BackgroundTransparency = 1
HeaderDivider.Parent = MainFrame

local Sidebar = Instance.new("Frame")
Sidebar.Name = "Sidebar"
Sidebar.Size = UDim2.new(0, SIDEBAR_W, 1, -(IS_MOBILE and 61 or 56))
Sidebar.Position = UDim2.new(0, 0, 0, IS_MOBILE and 61 or 56)
Sidebar.BackgroundColor3 = Color3.fromRGB(5, 5, 5)
Sidebar.BackgroundTransparency = 1
Sidebar.BorderSizePixel = 0
Sidebar.Parent = MainFrame

local SidebarLayout = Instance.new("UIListLayout")
SidebarLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
SidebarLayout.VerticalAlignment = Enum.VerticalAlignment.Top
SidebarLayout.SortOrder = Enum.SortOrder.LayoutOrder
SidebarLayout.Padding = UDim.new(0, IS_MOBILE and 8 or 6)
SidebarLayout.Parent = Sidebar

local SidebarPadding = Instance.new("UIPadding")
SidebarPadding.PaddingTop = UDim.new(0, 15)
SidebarPadding.PaddingLeft = UDim.new(0, 12)
SidebarPadding.PaddingRight = UDim.new(0, 12)
SidebarPadding.Parent = Sidebar

local SidebarDivider = Instance.new("Frame")
SidebarDivider.Name = "SidebarDivider"
SidebarDivider.Size = UDim2.new(0, 1, 1, -(IS_MOBILE and 61 or 56))
SidebarDivider.Position = UDim2.new(0, SIDEBAR_W, 0, IS_MOBILE and 61 or 56)
SidebarDivider.BackgroundColor3 = Color3.fromRGB(120, 80, 200)
SidebarDivider.BorderSizePixel = 0
SidebarDivider.BackgroundTransparency = 1
SidebarDivider.Parent = MainFrame

local ContentContainer = Instance.new("Frame")
ContentContainer.Name = "ContentContainer"
ContentContainer.Size = UDim2.new(1, -(SIDEBAR_W + 1), 1, -(IS_MOBILE and 61 or 56))
ContentContainer.Position = UDim2.new(0, SIDEBAR_W + 1, 0, IS_MOBILE and 61 or 56)
ContentContainer.BackgroundTransparency = 1
ContentContainer.Parent = MainFrame

-- ==========================================
-- Dragging (PC + Mobile)
-- ==========================================
local dragging, dragInput, dragStart, startPos
TopBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
        local conn
        conn = input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
                conn:Disconnect()
            end
        end)
    end
end)

TopBar.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

-- ==========================================
-- Category Management
-- ==========================================
local categories = {}
local currentCategory = nil

local function CreateCategory(name, iconId)
    local CategoryButton = Instance.new("TextButton")
    CategoryButton.Name = name .. "Button"
    CategoryButton.Size = UDim2.new(1, 0, 0, IS_MOBILE and 46 or 38)
    CategoryButton.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    CategoryButton.BackgroundTransparency = 1
    CategoryButton.AutoButtonColor = false
    CategoryButton.Font = Enum.Font.GothamMedium
    CategoryButton.Text = ""
    CategoryButton.Parent = Sidebar

    local BtnCorner = Instance.new("UICorner")
    BtnCorner.CornerRadius = UDim.new(0, 8)
    BtnCorner.Parent = CategoryButton

    local Icon = Instance.new("ImageLabel")
    Icon.Name = "Icon"
    Icon.Size = UDim2.new(0, IS_MOBILE and 22 or 18, 0, IS_MOBILE and 22 or 18)
    Icon.Position = UDim2.new(0, 12, 0.5, -(IS_MOBILE and 11 or 9))
    Icon.BackgroundTransparency = 1
    Icon.Image = iconId or "rbxassetid://10723346959"
    Icon.ImageColor3 = Color3.fromRGB(180, 180, 180)
    Icon.Parent = CategoryButton

    local Label = Instance.new("TextLabel")
    Label.Name = "Label"
    Label.Size = UDim2.new(1, -40, 1, 0)
    Label.Position = UDim2.new(0, 38, 0, 0)
    Label.BackgroundTransparency = 1
    Label.Font = Enum.Font.GothamMedium
    Label.Text = name
    Label.TextColor3 = Color3.fromRGB(180, 180, 180)
    Label.TextSize = IS_MOBILE and 15 or 13
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = CategoryButton

    local PageFrame = Instance.new("ScrollingFrame")
    PageFrame.Name = name .. "Page"
    PageFrame.Size = UDim2.new(1, 0, 1, 0)
    PageFrame.BackgroundTransparency = 1
    PageFrame.BorderSizePixel = 0
    PageFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    PageFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
    PageFrame.ScrollBarThickness = IS_MOBILE and 5 or 3
    PageFrame.ScrollBarImageColor3 = Color3.fromRGB(120, 80, 200)
    PageFrame.Visible = false
    PageFrame.Parent = ContentContainer

    local PageLayout = Instance.new("UIListLayout")
    PageLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    PageLayout.VerticalAlignment = Enum.VerticalAlignment.Top
    PageLayout.SortOrder = Enum.SortOrder.LayoutOrder
    PageLayout.Padding = UDim.new(0, IS_MOBILE and 12 or 10)
    PageLayout.Parent = PageFrame

    local PagePadding = Instance.new("UIPadding")
    PagePadding.PaddingTop = UDim.new(0, 16)
    PagePadding.PaddingBottom = UDim.new(0, 16)
    PagePadding.PaddingLeft = UDim.new(0, IS_MOBILE and 14 or 20)
    PagePadding.PaddingRight = UDim.new(0, IS_MOBILE and 14 or 20)
    PagePadding.Parent = PageFrame

    categories[name] = {
        Button = CategoryButton,
        Page = PageFrame,
        Icon = Icon,
        Label = Label
    }

    CategoryButton.MouseEnter:Connect(function()
        if currentCategory ~= name and not IS_MOBILE then
            TweenService:Create(CategoryButton, TweenInfo.new(0.2), {BackgroundTransparency = 0.5}):Play()
        end
    end)

    CategoryButton.MouseLeave:Connect(function()
        if currentCategory ~= name and not IS_MOBILE then
            TweenService:Create(CategoryButton, TweenInfo.new(0.2), {BackgroundTransparency = 1}):Play()
        end
    end)

    CategoryButton.MouseButton1Click:Connect(function()
        for catName, catData in pairs(categories) do
            if catName == name then
                catData.Page.Visible = true
                TweenService:Create(catData.Button, TweenInfo.new(0.2), {BackgroundTransparency = 0}):Play()
                catData.Icon.ImageColor3 = Color3.fromRGB(180, 140, 255)
                catData.Label.TextColor3 = Color3.fromRGB(255, 255, 255)
                currentCategory = name
            else
                catData.Page.Visible = false
                TweenService:Create(catData.Button, TweenInfo.new(0.2), {BackgroundTransparency = 1}):Play()
                catData.Icon.ImageColor3 = Color3.fromRGB(180, 180, 180)
                catData.Label.TextColor3 = Color3.fromRGB(180, 180, 180)
            end
        end
    end)

    if not currentCategory then
        currentCategory = name
        PageFrame.Visible = true
        CategoryButton.BackgroundTransparency = 0
        Icon.ImageColor3 = Color3.fromRGB(180, 140, 255)
        Label.TextColor3 = Color3.fromRGB(255, 255, 255)
    end

    return PageFrame
end

local autoFarmPage = CreateCategory("Auto Farm", "rbxassetid://10709769841")
local movementPage = CreateCategory("Movement", "rbxassetid://10747373176")
local visualsPage  = CreateCategory("Visuals",  "rbxassetid://10723346959")
local playerPage   = CreateCategory("Player",   "rbxassetid://10747372167")
local settingsPage = CreateCategory("Settings", "rbxassetid://10734950309")

print("[diox616 × Nyx] Categories created:", currentCategory)

-- ==========================================
-- UI Components
-- ==========================================

local function AddToggle(parentPage, title, description, defaultState, callback)
    local toggled = defaultState or false

    local ToggleContainer = Instance.new("Frame")
    ToggleContainer.Size = UDim2.new(1, 0, 0, IS_MOBILE and 58 or 50)
    ToggleContainer.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
    ToggleContainer.BackgroundTransparency = 0.5
    ToggleContainer.BorderSizePixel = 0
    ToggleContainer.Parent = parentPage

    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 8)
    Corner.Parent = ToggleContainer

    local Stroke = Instance.new("UIStroke")
    Stroke.Color = Color3.fromRGB(120, 80, 200)
    Stroke.Transparency = 0.7
    Stroke.Thickness = 1
    Stroke.Parent = ToggleContainer

    local TLabel = Instance.new("TextLabel")
    TLabel.Size = UDim2.new(1, -80, 0, 18)
    TLabel.Position = UDim2.new(0, 15, 0, IS_MOBILE and 10 or 8)
    TLabel.BackgroundTransparency = 1
    TLabel.Font = Enum.Font.GothamBold
    TLabel.Text = title
    TLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    TLabel.TextSize = IS_MOBILE and 15 or 13
    TLabel.TextXAlignment = Enum.TextXAlignment.Left
    TLabel.Parent = ToggleContainer

    local DLabel = Instance.new("TextLabel")
    DLabel.Size = UDim2.new(1, -80, 0, 15)
    DLabel.Position = UDim2.new(0, 15, 0, IS_MOBILE and 30 or 26)
    DLabel.BackgroundTransparency = 1
    DLabel.Font = Enum.Font.Gotham
    DLabel.Text = description or ""
    DLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
    DLabel.TextSize = IS_MOBILE and 13 or 11
    DLabel.TextXAlignment = Enum.TextXAlignment.Left
    DLabel.Parent = ToggleContainer

    local SwitchBg = Instance.new("Frame")
    SwitchBg.Size = UDim2.new(0, IS_MOBILE and 52 or 42, 0, IS_MOBILE and 28 or 22)
    SwitchBg.Position = UDim2.new(1, IS_MOBILE and -64 or -54, 0.5, IS_MOBILE and -14 or -11)
    SwitchBg.BackgroundColor3 = toggled and Color3.fromRGB(120, 80, 200) or Color3.fromRGB(35, 35, 35)
    SwitchBg.BorderSizePixel = 0
    SwitchBg.Parent = ToggleContainer

    local SwitchCorner = Instance.new("UICorner")
    SwitchCorner.CornerRadius = UDim.new(1, 0)
    SwitchCorner.Parent = SwitchBg

    local SwitchKnob = Instance.new("Frame")
    SwitchKnob.Size = UDim2.new(0, IS_MOBILE and 20 or 16, 0, IS_MOBILE and 20 or 16)
    SwitchKnob.Position = toggled and UDim2.new(1, -(IS_MOBILE and 24 or 19), 0.5, -(IS_MOBILE and 10 or 8)) or UDim2.new(0, IS_MOBILE and 4 or 3, 0.5, -(IS_MOBILE and 10 or 8))
    SwitchKnob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    SwitchKnob.BorderSizePixel = 0
    SwitchKnob.Parent = SwitchBg

    local KnobCorner = Instance.new("UICorner")
    KnobCorner.CornerRadius = UDim.new(1, 0)
    KnobCorner.Parent = SwitchKnob

    local ClickButton = Instance.new("TextButton")
    ClickButton.Size = UDim2.new(1, 0, 1, 0)
    ClickButton.BackgroundTransparency = 1
    ClickButton.Text = ""
    ClickButton.Parent = ToggleContainer

    local function UpdateToggle(state, noCallback)
        toggled = state
        local targetColor = toggled and Color3.fromRGB(120, 80, 200) or Color3.fromRGB(35, 35, 35)
        local targetPos = toggled and UDim2.new(1, -(IS_MOBILE and 24 or 19), 0.5, -(IS_MOBILE and 10 or 8)) or UDim2.new(0, IS_MOBILE and 4 or 3, 0.5, -(IS_MOBILE and 10 or 8))
        
        TweenService:Create(SwitchBg, TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {BackgroundColor3 = targetColor}):Play()
        TweenService:Create(SwitchKnob, TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = targetPos}):Play()
        
        if not noCallback and callback then
            pcall(callback, toggled)
        end
    end

    ClickButton.MouseButton1Click:Connect(function()
        UpdateToggle(not toggled)
    end)

    return {
        Set = function(state) UpdateToggle(state) end,
        Get = function() return toggled end
    }
end

local function AddSlider(parentPage, title, min, max, default, callback)
    local value = default or min

    local SliderContainer = Instance.new("Frame")
    SliderContainer.Size = UDim2.new(1, 0, 0, IS_MOBILE and 68 or 60)
    SliderContainer.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
    SliderContainer.BackgroundTransparency = 0.5
    SliderContainer.BorderSizePixel = 0
    SliderContainer.Parent = parentPage

    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 8)
    Corner.Parent = SliderContainer

    local Stroke = Instance.new("UIStroke")
    Stroke.Color = Color3.fromRGB(120, 80, 200)
    Stroke.Transparency = 0.7
    Stroke.Thickness = 1
    Stroke.Parent = SliderContainer

    local TLabel = Instance.new("TextLabel")
    TLabel.Size = UDim2.new(1, -70, 0, 18)
    TLabel.Position = UDim2.new(0, 15, 0, IS_MOBILE and 12 or 10)
    TLabel.BackgroundTransparency = 1
    TLabel.Font = Enum.Font.GothamBold
    TLabel.Text = title
    TLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    TLabel.TextSize = IS_MOBILE and 15 or 13
    TLabel.TextXAlignment = Enum.TextXAlignment.Left
    TLabel.Parent = SliderContainer

    local ValueLabel = Instance.new("TextLabel")
    ValueLabel.Size = UDim2.new(0, 60, 0, 18)
    ValueLabel.Position = UDim2.new(1, -65, 0, IS_MOBILE and 12 or 10)
    ValueLabel.BackgroundTransparency = 1
    ValueLabel.Font = Enum.Font.GothamMedium
    ValueLabel.Text = tostring(value)
    ValueLabel.TextColor3 = Color3.fromRGB(180, 140, 255)
    ValueLabel.TextSize = IS_MOBILE and 15 or 13
    ValueLabel.TextXAlignment = Enum.TextXAlignment.Right
    ValueLabel.Parent = SliderContainer

    local SliderTrack = Instance.new("Frame")
    SliderTrack.Size = UDim2.new(1, -30, 0, IS_MOBILE and 8 or 6)
    SliderTrack.Position = UDim2.new(0, 15, 0, IS_MOBILE and 46 or 40)
    SliderTrack.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    SliderTrack.BorderSizePixel = 0
    SliderTrack.Parent = SliderContainer

    local TrackCorner = Instance.new("UICorner")
    TrackCorner.CornerRadius = UDim.new(1, 0)
    TrackCorner.Parent = SliderTrack

    local SliderFill = Instance.new("Frame")
    SliderFill.Size = UDim2.new(math.clamp((value - min) / (max - min), 0, 1), 0, 1, 0)
    SliderFill.BackgroundColor3 = Color3.fromRGB(120, 80, 200)
    SliderFill.BorderSizePixel = 0
    SliderFill.Parent = SliderTrack

    local FillCorner = Instance.new("UICorner")
    FillCorner.CornerRadius = UDim.new(1, 0)
    FillCorner.Parent = SliderFill

    local SliderKnob = Instance.new("Frame")
    SliderKnob.Size = UDim2.new(0, IS_MOBILE and 22 or 12, 0, IS_MOBILE and 22 or 12)
    SliderKnob.AnchorPoint = Vector2.new(0.5, 0.5)
    SliderKnob.Position = UDim2.new(SliderFill.Size.X.Scale, 0, 0.5, 0)
    SliderKnob.BackgroundColor3 = Color3.fromRGB(200, 180, 255)
    SliderKnob.BorderSizePixel = 0
    SliderKnob.Parent = SliderTrack

    local KnobCorner = Instance.new("UICorner")
    KnobCorner.CornerRadius = UDim.new(1, 0)
    KnobCorner.Parent = SliderKnob

    if IS_MOBILE then
        local KnobStroke = Instance.new("UIStroke")
        KnobStroke.Color = Color3.fromRGB(120, 80, 200)
        KnobStroke.Thickness = 2
        KnobStroke.Parent = SliderKnob
    end

    local sliding = false

    local function UpdateSlider(input)
        local pos = UDim2.new(math.clamp((input.Position.X - SliderTrack.AbsolutePosition.X) / SliderTrack.AbsoluteSize.X, 0, 1), 0, 1, 0)
        SliderFill.Size = pos
        SliderKnob.Position = UDim2.new(pos.X.Scale, 0, 0.5, 0)
        
        local rawValue = min + ((max - min) * pos.X.Scale)
        value = math.floor(rawValue * 10 + 0.5) / 10
        ValueLabel.Text = tostring(value)
        
        if callback then
            pcall(callback, value)
        end
    end

    SliderTrack.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            sliding = true
            UpdateSlider(input)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            sliding = false
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if sliding and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            UpdateSlider(input)
        end
    end)

    return {
        Set = function(v)
            value = math.clamp(v, min, max)
            local scale = (value - min) / (max - min)
            SliderFill.Size = UDim2.new(scale, 0, 1, 0)
            SliderKnob.Position = UDim2.new(scale, 0, 0.5, 0)
            ValueLabel.Text = tostring(value)
            if callback then pcall(callback, value) end
        end,
        Get = function() return value end
    }
end

local function AddButton(parentPage, title, description, callback)
    local ButtonFrame = Instance.new("Frame")
    ButtonFrame.Size = UDim2.new(1, 0, 0, IS_MOBILE and 52 or 45)
    ButtonFrame.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
    ButtonFrame.BackgroundTransparency = 0.5
    ButtonFrame.BorderSizePixel = 0
    ButtonFrame.Parent = parentPage

    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 8)
    Corner.Parent = ButtonFrame

    local Stroke = Instance.new("UIStroke")
    Stroke.Color = Color3.fromRGB(120, 80, 200)
    Stroke.Transparency = 0.7
    Stroke.Thickness = 1
    Stroke.Parent = ButtonFrame

    local TLabel = Instance.new("TextLabel")
    TLabel.Size = UDim2.new(1, -20, 1, 0)
    TLabel.Position = UDim2.new(0, 15, 0, 0)
    TLabel.BackgroundTransparency = 1
    TLabel.Font = Enum.Font.GothamBold
    TLabel.Text = title
    TLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    TLabel.TextSize = IS_MOBILE and 15 or 13
    TLabel.TextXAlignment = Enum.TextXAlignment.Left
    TLabel.Parent = ButtonFrame

    local ClickButton = Instance.new("TextButton")
    ClickButton.Size = UDim2.new(1, 0, 1, 0)
    ClickButton.BackgroundTransparency = 1
    ClickButton.Text = ""
    ClickButton.Parent = ButtonFrame

    ClickButton.MouseEnter:Connect(function()
        if not IS_MOBILE then
            TweenService:Create(ButtonFrame, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(25, 25, 25)}):Play()
            TweenService:Create(Stroke, TweenInfo.new(0.2), {Transparency = 0}):Play()
        end
    end)

    ClickButton.MouseLeave:Connect(function()
        if not IS_MOBILE then
            TweenService:Create(ButtonFrame, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(12, 12, 12)}):Play()
            TweenService:Create(Stroke, TweenInfo.new(0.2), {Transparency = 0.7}):Play()
        end
    end)

    ClickButton.MouseButton1Click:Connect(function()
        TweenService:Create(ButtonFrame, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(120, 80, 200)}):Play()
        task.delay(0.15, function()
            TweenService:Create(ButtonFrame, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(12, 12, 12)}):Play()
        end)
        
        if callback then
            pcall(callback)
        end
    end)
end

local function AddDropdown(parentPage, title, options, defaultOption, callback)
    local selected = defaultOption or options[1]
    local isExpanded = false

    local DropdownContainer = Instance.new("Frame")
    DropdownContainer.Size = UDim2.new(1, 0, 0, IS_MOBILE and 54 or 48)
    DropdownContainer.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
    DropdownContainer.BackgroundTransparency = 0.5
    DropdownContainer.BorderSizePixel = 0
    DropdownContainer.ClipsDescendants = true
    DropdownContainer.Parent = parentPage

    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 8)
    Corner.Parent = DropdownContainer

    local Stroke = Instance.new("UIStroke")
    Stroke.Color = Color3.fromRGB(120, 80, 200)
    Stroke.Transparency = 0.7
    Stroke.Thickness = 1
    Stroke.Parent = DropdownContainer

    local TLabel = Instance.new("TextLabel")
    TLabel.Size = UDim2.new(0.5, -15, 0, IS_MOBILE and 54 or 48)
    TLabel.Position = UDim2.new(0, 15, 0, 0)
    TLabel.BackgroundTransparency = 1
    TLabel.Font = Enum.Font.GothamBold
    TLabel.Text = title
    TLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    TLabel.TextSize = IS_MOBILE and 15 or 13
    TLabel.TextXAlignment = Enum.TextXAlignment.Left
    TLabel.Parent = DropdownContainer

    local SelectedBtn = Instance.new("TextButton")
    SelectedBtn.Size = UDim2.new(0.48, -10, 0, IS_MOBILE and 38 or 32)
    SelectedBtn.Position = UDim2.new(0.52, 0, 0, 8)
    SelectedBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    SelectedBtn.BorderSizePixel = 0
    SelectedBtn.Font = Enum.Font.GothamMedium
    SelectedBtn.Text = tostring(selected) .. "  ▼"
    SelectedBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    SelectedBtn.TextSize = IS_MOBILE and 14 or 12
    SelectedBtn.Parent = DropdownContainer

    local BtnCorner = Instance.new("UICorner")
    BtnCorner.CornerRadius = UDim.new(0, 6)
    BtnCorner.Parent = SelectedBtn

    local ListHolder = Instance.new("ScrollingFrame")
    ListHolder.Size = UDim2.new(1, -30, 0, 0)
    ListHolder.Position = UDim2.new(0, 15, 0, IS_MOBILE and 54 or 48)
    ListHolder.BackgroundTransparency = 1
    ListHolder.BorderSizePixel = 0
    ListHolder.ScrollBarThickness = 2
    ListHolder.ScrollBarImageColor3 = Color3.fromRGB(120, 80, 200)
    ListHolder.AutomaticCanvasSize = Enum.AutomaticSize.Y
    ListHolder.CanvasSize = UDim2.new(0, 0, 0, 0)
    ListHolder.Parent = DropdownContainer

    local ListLayout = Instance.new("UIListLayout")
    ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    ListLayout.Padding = UDim.new(0, 4)
    ListLayout.Parent = ListHolder

    local function RefreshOptions(newOptions)
        for _, child in ipairs(ListHolder:GetChildren()) do
            if child:IsA("TextButton") then
                child:Destroy()
            end
        end
        for _, opt in ipairs(newOptions) do
            local OptBtn = Instance.new("TextButton")
            OptBtn.Size = UDim2.new(1, 0, 0, IS_MOBILE and 34 or 28)
            OptBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
            OptBtn.BorderSizePixel = 0
            OptBtn.Font = Enum.Font.Gotham
            OptBtn.Text = tostring(opt)
            OptBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
            OptBtn.TextSize = IS_MOBILE and 14 or 12
            OptBtn.Parent = ListHolder

            local OptCorner = Instance.new("UICorner")
            OptCorner.CornerRadius = UDim.new(0, 4)
            OptCorner.Parent = OptBtn

            OptBtn.MouseButton1Click:Connect(function()
                selected = opt
                SelectedBtn.Text = tostring(selected) .. "  ▼"
                isExpanded = false
                TweenService:Create(DropdownContainer, TweenInfo.new(0.2), {Size = UDim2.new(1, 0, 0, IS_MOBILE and 54 or 48)}):Play()
                ListHolder.Size = UDim2.new(1, -30, 0, 0)
                if callback then pcall(callback, selected) end
            end)
        end
    end

    RefreshOptions(options)

    SelectedBtn.MouseButton1Click:Connect(function()
        isExpanded = not isExpanded
        if isExpanded then
            local listHeight = math.clamp(#options * (IS_MOBILE and 38 or 32), IS_MOBILE and 38 or 32, IS_MOBILE and 160 or 130)
            ListHolder.Size = UDim2.new(1, -30, 0, listHeight)
            TweenService:Create(DropdownContainer, TweenInfo.new(0.25), {Size = UDim2.new(1, 0, 0, (IS_MOBILE and 54 or 48) + listHeight + 4)}):Play()
        else
            TweenService:Create(DropdownContainer, TweenInfo.new(0.2), {Size = UDim2.new(1, 0, 0, IS_MOBILE and 54 or 48)}):Play()
            ListHolder.Size = UDim2.new(1, -30, 0, 0)
        end
    end)

    return {
        Get = function() return selected end,
        Set = function(val)
            selected = val
            SelectedBtn.Text = tostring(selected) .. "  ▼"
            if callback then pcall(callback, selected) end
        end,
        UpdateList = function(newList)
            options = newList
            RefreshOptions(newList)
            if not table.find(options, selected) then
                selected = options[1] or "None"
                SelectedBtn.Text = tostring(selected) .. "  ▼"
                if callback then pcall(callback, selected) end
            end
        end
    }
end

print("[diox616 × Nyx] UI components defined")

-- ==========================================
-- Movement & AntiCheat Core
-- ==========================================

local tpWalkEnabled = false
local currentSpeedValue = 16
local currentSmoothness = 0.35
local antiCheatBypassed = false
local joystickEnabled = false
local joystickVector = Vector3.zero

local function GetRoot()
    local char = LocalPlayer.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function TriggerAntiCheatBypass(silent)
    local character = LocalPlayer.Character
    if not character then return false end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    
    if not rootPart then return false end
    
    Camera.CameraType = Enum.CameraType.Custom
    Camera.CameraSubject = rootPart
    
    if humanoid then
        pcall(function()
            humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, false)
            humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
            humanoid:SetStateEnabled(Enum.HumanoidStateType.Freefall, false)
            humanoid:SetStateEnabled(Enum.HumanoidStateType.Landed, false)
            humanoid:ChangeState(Enum.HumanoidStateType.Physics)
        end)
        
        task.delay(0.1, function()
            if humanoid and humanoid.Parent then
                local animate = character:FindFirstChild("Animate")
                if animate then animate:Destroy() end
                humanoid:Destroy()
            end
        end)
        
        antiCheatBypassed = true
        if not silent then
            Notify("AntiCheat", "Humanoid removed. Camera locked to root.", 2.5)
        end
        return true
    end
    return false
end

local function RestoreAntiCheat()
    if LocalPlayer.Character then
        LocalPlayer.Character:BreakJoints()
    end
    antiCheatBypassed = false
end

LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(0.5)
    if antiCheatBypassed then
        task.wait(1)
        TriggerAntiCheatBypass(true)
    end
end)

-- FIXED: No more RenderStepped:Wait() inside Heartbeat — uses RenderStepped directly with deltaTime
RunService.RenderStepped:Connect(function(deltaTime)
    if not tpWalkEnabled then return end
    
    local rootPart = GetRoot()
    if not rootPart or not rootPart.Parent then return end
    
    local moveDirection = Vector3.zero
    
    if joystickEnabled and joystickVector.Magnitude > 0 then
        moveDirection = joystickVector
    else
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
    end
    
    moveDirection = Vector3.new(moveDirection.X, 0, moveDirection.Z)
    
    if moveDirection.Magnitude > 0 then
        moveDirection = moveDirection.Unit
        
        -- Single smooth step per frame — no yielding
        local travelDist = currentSpeedValue * deltaTime * currentSmoothness
        rootPart.CFrame = rootPart.CFrame + (moveDirection * travelDist)
        
        rootPart.AssemblyLinearVelocity = Vector3.zero
        rootPart.AssemblyAngularVelocity = Vector3.zero
    end
end)

print("[diox616 × Nyx] Movement core initialized")

-- ==========================================
-- Movement Page UI
-- ==========================================

AddToggle(movementPage, "TPWalk Speed", "Smooth TP-based movement", false, function(state)
    tpWalkEnabled = state
    if tpWalkEnabled then
        Notify("Movement", "TPWalk enabled (" .. currentSpeedValue .. " spd)", 2.5)
    else
        Notify("Movement", "TPWalk disabled", 2.5)
    end
end)

AddSlider(movementPage, "Speed Value", 16, 1000, 16, function(value)
    currentSpeedValue = value
end)

AddSlider(movementPage, "TP Smoothness", 0.1, 2.0, 0.35, function(value)
    currentSmoothness = value
end)

AddToggle(movementPage, "AntiCheat Bypass", "Removes Humanoid, preserves camera. Re-applies on respawn.", false, function(state)
    if state then
        TriggerAntiCheatBypass(false)
    else
        RestoreAntiCheat()
        Notify("AntiCheat", "Restored — character will respawn", 2)
    end
end)

-- Mobile joystick
local joystickGui = nil

local function CreateJoystick()
    local joyGui = Instance.new("Frame")
    joyGui.Name = "NyxJoystick"
    joyGui.Size = UDim2.new(0, 150, 0, 150)
    joyGui.Position = UDim2.new(0, 25, 1, -175)
    joyGui.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    joyGui.BackgroundTransparency = 0.3
    joyGui.BorderSizePixel = 0
    joyGui.Visible = false
    joyGui.Parent = ScreenGui
    
    local jCorner = Instance.new("UICorner")
    jCorner.CornerRadius = UDim.new(1, 0)
    jCorner.Parent = joyGui
    
    local jStroke = Instance.new("UIStroke")
    jStroke.Color = Color3.fromRGB(120, 80, 200)
    jStroke.Thickness = 2
    jStroke.Parent = joyGui
    
    local joyKnob = Instance.new("Frame")
    joyKnob.Size = UDim2.new(0, 60, 0, 60)
    joyKnob.Position = UDim2.new(0.5, -30, 0.5, -30)
    joyKnob.BackgroundColor3 = Color3.fromRGB(120, 80, 200)
    joyKnob.BorderSizePixel = 0
    joyKnob.Parent = joyGui
    
    local kCorner = Instance.new("UICorner")
    kCorner.CornerRadius = UDim.new(1, 0)
    kCorner.Parent = joyKnob
    
    local kStroke = Instance.new("UIStroke")
    kStroke.Color = Color3.fromRGB(200, 180, 255)
    kStroke.Thickness = 2
    kStroke.Parent = joyKnob
    
    local joystickActive = false
    local joystickTouchInput = nil
    
    joyGui.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch then
            joystickActive = true
            joystickTouchInput = input
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if joystickActive and input == joystickTouchInput then
            local center = joyGui.AbsolutePosition + joyGui.AbsoluteSize / 2
            local delta = input.Position - center
            local maxDist = joyGui.AbsoluteSize.X / 2 - 30
            local clampedDelta = delta.Magnitude > maxDist and (delta.Unit * maxDist) or delta
            
            joyKnob.Position = UDim2.new(0.5, clampedDelta.X - 30, 0.5, clampedDelta.Y - 30)
            
            local normalized = Vector2.new(clampedDelta.X / maxDist, clampedDelta.Y / maxDist)
            
            if normalized.Magnitude > 0.15 then
                local forward = Camera.CFrame.LookVector
                local right = Camera.CFrame.RightVector
                joystickVector = (right * normalized.X) + (forward * -normalized.Y)
            else
                joystickVector = Vector3.zero
            end
        end
    end)
    
    UserInputService.InputEnded:Connect(function(input)
        if input == joystickTouchInput then
            joystickActive = false
            joystickTouchInput = nil
            joyKnob.Position = UDim2.new(0.5, -30, 0.5, -30)
            joystickVector = Vector3.zero
        end
    end)
    
    return joyGui
end

AddToggle(movementPage, "Virtual Joystick", "On-screen analog stick for mobile", false, function(state)
    joystickEnabled = state
    if state then
        if not joystickGui then
            joystickGui = CreateJoystick()
        end
        joystickGui.Visible = IS_MOBILE
        if IS_MOBILE then
            Notify("Movement", "Joystick enabled — left side of screen", 3)
        else
            Notify("Movement", "Joystick is mobile-only", 3)
        end
    else
        if joystickGui then
            joystickGui.Visible = false
        end
        joystickVector = Vector3.zero
    end
end)

AddButton(movementPage, "Reset Character", "Instantly respawns your character", function()
    local character = LocalPlayer.Character
    if character then
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.Health = 0
        else
            local fakeHumanoid = Instance.new("Humanoid")
            fakeHumanoid.Parent = character
            fakeHumanoid.Health = 0
        end
        Notify("Player", "Character reset", 2)
    end
end)

print("[diox616 × Nyx] Movement page built")

-- ==========================================
-- Egg Scanning & Auto Farm
-- ==========================================

local function GetEggContainer()
    return Workspace:FindFirstChild("AreaEggSlotsClient", true)
end

local function GetModelVolume(model)
    if model:IsA("Model") then
        local _, size = model:GetBoundingBox()
        return size.X * size.Y * size.Z
    elseif model:IsA("BasePart") then
        return model.Size.X * model.Size.Y * model.Size.Z
    end
    return 0
end

local function IsParasiteEgg(model)
    return model:FindFirstChild("MonsterParasiteVisual", true) ~= nil
end

local function IsSecretEgg(model)
    local descendants = model:GetDescendants()
    for i = 1, #descendants do
        local nameLower = string.lower(descendants[i].Name)
        if nameLower == "fx" or string.find(nameLower, "fx", 1, true) then
            return true
        end
    end
    return false
end

local function GetModelPosition(model)
    if model:IsA("Model") then
        if model.PrimaryPart then
            return model.PrimaryPart.Position
        end
        return model:GetPivot().Position
    elseif model:IsA("BasePart") then
        return model.Position
    end
    return Vector3.zero
end

local detectedZones = {}

local function RescanZones()
    local signs = {}
    local grounds = {}
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj.Name == "RequiredSpeedSign" then
            table.insert(signs, obj)
        elseif obj.Name == "Ground" and obj:IsA("BasePart") then
            table.insert(grounds, obj)
        end
    end
    local zoneList = {}
    for _, sign in ipairs(signs) do
        if sign and sign.Parent then
            local sPos = GetModelPosition(sign)
            local closestGround = nil
            local minDist = math.huge
            for _, ground in ipairs(grounds) do
                if ground and ground.Parent then
                    local d = (sPos - ground.Position).Magnitude
                    if d < minDist then minDist = d closestGround = ground end
                end
            end
            table.insert(zoneList, {
                Sign = sign, SignPosition = sPos, Ground = closestGround,
                GroundPosition = closestGround and closestGround.Position or sPos,
                DistanceToGround = minDist
            })
        end
    end
    table.sort(zoneList, function(a, b) return a.DistanceToGround < b.DistanceToGround end)
    for index = 1, #zoneList do
        zoneList[index].Index = index
        zoneList[index].Name = "Zone " .. tostring(index)
    end
    detectedZones = zoneList
    return detectedZones
end

local function GetZoneOfPosition(pos)
    if #detectedZones == 0 then RescanZones() end
    local closestZone = nil
    local minDist = math.huge
    for _, zone in ipairs(detectedZones) do
        local dist = (pos - zone.SignPosition).Magnitude
        if dist < minDist then minDist = dist closestZone = zone end
    end
    return closestZone
end

local TRAP_AVOID_RADIUS = 5

local function GetActiveTraps()
    local traps = {}
    local debrisFolder = Workspace:FindFirstChild("_DEBRIS")
    local searchList = debrisFolder and debrisFolder:GetChildren() or Workspace:GetDescendants()
    for _, obj in ipairs(searchList) do
        if obj.Name == "PlayerTrap" and (obj:IsA("Model") or obj:IsA("BasePart")) then
            table.insert(traps, GetModelPosition(obj))
        end
    end
    return traps
end

local function CalculateAvoidanceDirection(currentPos, targetPos, traps)
    local moveVec = (targetPos - currentPos)
    local moveDir = Vector3.new(moveVec.X, 0, moveVec.Z)
    if moveDir.Magnitude == 0 then return Vector3.zero end
    moveDir = moveDir.Unit
    local sideAvoidForce = Vector3.zero
    local normalLeft = Vector3.new(-moveDir.Z, 0, moveDir.X)
    for _, trapPos in ipairs(traps) do
        local toTrap = Vector3.new(trapPos.X - currentPos.X, 0, trapPos.Z - currentPos.Z)
        local distToTrap = toTrap.Magnitude
        if distToTrap < TRAP_AVOID_RADIUS and distToTrap > 0.05 then
            local forwardDot = moveDir:Dot(toTrap.Unit)
            if forwardDot > 0.15 then
                local sideDot = normalLeft:Dot(toTrap.Unit)
                local detourSide = (sideDot >= 0) and -normalLeft or normalLeft
                local forceFactor = (1 - (distToTrap / TRAP_AVOID_RADIUS)) * 3.5
                sideAvoidForce = sideAvoidForce + (detourSide * forceFactor)
            end
        end
    end
    local finalDir = moveDir + sideAvoidForce
    return (finalDir.Magnitude > 0) and finalDir.Unit or moveDir
end

local autoFarmEnabled = false
local farmEggType = "Biggest Egg"
local farmSelectedZone = "All Zones"
local isCurrentlyFarming = false
local farmToken = 0

local function IsEggObject(obj)
    return obj and (obj:IsA("Model") or obj:IsA("BasePart"))
end

local function MoveToPosition(targetPos, timeout)
    timeout = timeout or 15
    local started = os.clock()
    while autoFarmEnabled and (os.clock() - started) < timeout do
        local rootPart = GetRoot()
        if not rootPart then task.wait(0.1) continue end
        local curPos = rootPart.Position
        local delta = targetPos - curPos
        local flatDist = Vector3.new(delta.X, 0, delta.Z).Magnitude
        if flatDist <= 1.5 then
            rootPart.CFrame = CFrame.new(targetPos)
            rootPart.AssemblyLinearVelocity = Vector3.zero
            rootPart.AssemblyAngularVelocity = Vector3.zero
            return true
        end
        local dt = RunService.RenderStepped:Wait()
        local moveSpeed = math.clamp(math.max(currentSpeedValue, 100), 100, 700)
        local travelDist = moveSpeed * dt
        local traps = GetActiveTraps()
        local steerDir = CalculateAvoidanceDirection(curPos, targetPos, traps)
        rootPart.AssemblyLinearVelocity = Vector3.zero
        rootPart.AssemblyAngularVelocity = Vector3.zero
        if travelDist >= flatDist and steerDir:Dot(delta.Unit) > 0.9 then
            rootPart.CFrame = CFrame.new(targetPos)
        else
            local nextPos = curPos + (steerDir * travelDist)
            local nextY = curPos.Y + ((targetPos.Y - curPos.Y) * math.clamp(travelDist / math.max(flatDist, 0.1), 0, 1))
            rootPart.CFrame = CFrame.new(Vector3.new(nextPos.X, nextY, nextPos.Z))
        end
    end
    return false
end

local function InteractWithEgg(egg)
    if not egg or not egg.Parent then return end
    local prompt = egg:FindFirstChildWhichIsA("ProximityPrompt", true)
    if prompt then
        pcall(function()
            prompt.Enabled = true
            prompt.HoldDuration = 0
            prompt.MaxActivationDistance = 50
            if typeof(fireproximityprompt) == "function" then
                fireproximityprompt(prompt, 1, true)
            else
                prompt:InputHoldBegin()
                task.wait(0.05)
                prompt:InputHoldEnd()
            end
        end)
    end
    pcall(function()
        if typeof(keypress) == "function" and typeof(keyrelease) == "function" then
            keypress(0x45)
            task.wait(0.04)
            keyrelease(0x45)
        end
    end)
end

local function GetGroundForZone(zone)
    if zone and zone.Ground and zone.Ground.Parent and zone.Ground:IsA("BasePart") then
        return zone.Ground
    end
    local root = GetRoot()
    if not root then return nil end
    local best, bestDist = nil, math.huge
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") and obj.Name == "Ground" then
            local d = (obj.Position - root.Position).Magnitude
            if d < bestDist then best = obj bestDist = d end
        end
    end
    return best
end

local function FindBestEgg()
    local container = GetEggContainer()
    if not container then return nil, nil end
    local eggModels = {}
    for _, child in ipairs(container:GetChildren()) do
        if IsEggObject(child) then
            local eggPos = GetModelPosition(child)
            local zone = GetZoneOfPosition(eggPos)
            local zoneAllowed = farmSelectedZone == "All Zones" or (zone and zone.Name == farmSelectedZone)
            if zoneAllowed then
                table.insert(eggModels, { Model = child, Zone = zone })
            end
        end
    end
    if #eggModels == 0 then return nil, nil end
    if farmEggType == "Biggest Egg" then
        local biggest, biggestVol, biggestZone = nil, -1, nil
        for _, item in ipairs(eggModels) do
            local vol = GetModelVolume(item.Model)
            if vol > biggestVol then biggest = item.Model biggestVol = vol biggestZone = item.Zone end
        end
        if biggest then return biggest, biggestZone end
    elseif farmEggType == "Parasite Egg" then
        for _, item in ipairs(eggModels) do
            if IsParasiteEgg(item.Model) then return item.Model, item.Zone end
        end
    elseif farmEggType == "Secret Egg" then
        for _, item in ipairs(eggModels) do
            if IsSecretEgg(item.Model) then return item.Model, item.Zone end
        end
    end
    return nil, nil
end

local function PickupEgg(egg)
    if not egg or not egg.Parent then return false end
    local root = GetRoot()
    if not root then return false end
    local targetEggPos = GetModelPosition(egg) + Vector3.new(0, 1.5, 0)
    local reached = MoveToPosition(targetEggPos, 10)
    if not reached then return false end
    root.Anchored = true
    root.AssemblyLinearVelocity = Vector3.zero
    root.AssemblyAngularVelocity = Vector3.zero
    local pickupTimeout = 2.5
    local pickupStarted = os.clock()
    local wasPickedUp = false
    while autoFarmEnabled and (os.clock() - pickupStarted) < pickupTimeout do
        if not egg or not egg.Parent or not egg:IsDescendantOf(Workspace) then
            wasPickedUp = true
            break
        end
        local currentTarget = GetModelPosition(egg) + Vector3.new(0, 1.5, 0)
        root.CFrame = CFrame.new(currentTarget)
        InteractWithEgg(egg)
        task.wait(0.08)
    end
    root.Anchored = false
    return wasPickedUp
end

local function DropEggAtGround(zone)
    local ground = GetGroundForZone(zone)
    if not ground then
        Notify("Auto Farm", "Ground not found for this zone", 2)
        return false
    end
    local dropPos = ground.Position + Vector3.new(0, ground.Size.Y * 0.5 + 3, 0)
    local reached = MoveToPosition(dropPos, 12)
    if not reached then return false end
    local root = GetRoot()
    if root then
        root.Anchored = true
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
        pcall(function()
            if typeof(firetouchinterest) == "function" then
                firetouchinterest(root, ground, 0)
                task.wait(0.05)
                firetouchinterest(root, ground, 1)
            end
        end)
    end
    task.wait(0.2)
    if root then root.Anchored = false end
    return true
end

local function StartFarmCycle()
    if isCurrentlyFarming or not autoFarmEnabled then return end
    TriggerAntiCheatBypass(true)
    isCurrentlyFarming = true
    farmToken = farmToken + 1
    local myToken = farmToken
    task.spawn(function()
        local failedAttempts = 0
        while autoFarmEnabled and myToken == farmToken do
            local egg, zone = FindBestEgg()
            if not egg then
                failedAttempts = failedAttempts + 1
                if failedAttempts >= 10 then
                    Notify("Auto Farm", "Searching for eggs...", 1.5)
                    failedAttempts = 0
                end
                task.wait(0.2)
                continue
            end
            failedAttempts = 0
            Notify("Auto Farm", "Target: " .. tostring(egg.Name), 1)
            local pickedUp = PickupEgg(egg)
            if not autoFarmEnabled or myToken ~= farmToken then break end
            if pickedUp then DropEggAtGround(zone) end
            task.wait(0.05)
        end
        local root = GetRoot()
        if root then root.Anchored = false end
        isCurrentlyFarming = false
    end)
end

local function StopFarmCycle()
    autoFarmEnabled = false
    farmToken = farmToken + 1
    local root = GetRoot()
    if root then root.Anchored = false end
    isCurrentlyFarming = false
end

AddDropdown(autoFarmPage, "Egg Type", {"Biggest Egg", "Parasite Egg", "Secret Egg"}, "Biggest Egg", function(val)
    farmEggType = val
    Notify("Auto Farm", "Target: " .. val, 2)
end)

local zoneDropdown = AddDropdown(autoFarmPage, "Zone", {"All Zones"}, "All Zones", function(val)
    farmSelectedZone = val
    Notify("Auto Farm", "Zone: " .. val, 2)
end)

task.spawn(function()
    task.wait(0.5)
    local zones = RescanZones()
    local list = {"All Zones"}
    for i = 1, #zones do table.insert(list, zones[i].Name) end
    if zoneDropdown then zoneDropdown.UpdateList(list) end
    while ScreenGui and ScreenGui.Parent do
        task.wait(5)
        if not ScreenGui or not ScreenGui.Parent then break end
        local updated = RescanZones()
        local newList = {"All Zones"}
        for i = 1, #updated do table.insert(newList, updated[i].Name) end
        if zoneDropdown then zoneDropdown.UpdateList(newList) end
    end
end)

AddToggle(autoFarmPage, "Auto Farm", "Finds egg, picks up, carries to ground", false, function(state)
    if state then
        autoFarmEnabled = true
        Notify("Auto Farm", "Started", 2)
        StartFarmCycle()
    else
        StopFarmCycle()
        Notify("Auto Farm", "Stopped", 2)
    end
end)

print("[diox616 × Nyx] Auto Farm page built")

-- ==========================================
-- Custom Sky & Atmosphere
-- ==========================================
local originalSky = Lighting:FindFirstChildOfClass("Sky")
if originalSky then originalSky = originalSky:Clone() originalSky.Name = "OriginalGameSky" end
local originalAtmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
if originalAtmosphere then originalAtmosphere = originalAtmosphere:Clone() originalAtmosphere.Name = "OriginalGameAtmosphere" end
local originalClouds = Workspace.Terrain:FindFirstChildOfClass("Clouds")
local originalClockTime = Lighting.ClockTime
local originalGeographicLatitude = Lighting.GeographicLatitude

local fallbackSkyPresets = {
    ["NightSky"] = {
        Bk = "rbxassetid://6444884346", Dn = "rbxassetid://6444884785", Ft = "rbxassetid://6444884346",
        Lf = "rbxassetid://6444884638", Rt = "rbxassetid://6444884131", Up = "rbxassetid://6444884929",
        ClockTime = 0,
        Atmosphere = { Density = 0.25, Offset = 0, Color = Color3.fromRGB(15, 20, 35), Decay = Color3.fromRGB(10, 10, 25), Glare = 0, Haze = 1 }
    },
    ["SpaceSky"] = {
        Bk = "rbxassetid://6130422174", Dn = "rbxassetid://6130422409", Ft = "rbxassetid://6130422174",
        Lf = "rbxassetid://6130422616", Rt = "rbxassetid://6130422874", Up = "rbxassetid://6130423086",
        ClockTime = 0,
        Atmosphere = { Density = 0.05, Offset = 0, Color = Color3.fromRGB(0, 0, 0), Decay = Color3.fromRGB(0, 0, 0), Glare = 0, Haze = 0 }
    },
    ["RealisticSky"] = {
        Bk = "rbxassetid://159454299", Dn = "rbxassetid://159454296", Ft = "rbxassetid://159454293",
        Lf = "rbxassetid://159454286", Rt = "rbxassetid://159454300", Up = "rbxassetid://159454288",
        ClockTime = 14,
        Atmosphere = { Density = 0.35, Offset = 0.25, Color = Color3.fromRGB(199, 210, 230), Decay = Color3.fromRGB(106, 120, 140), Glare = 0.2, Haze = 0.4 }
    }
}

local function CleanCurrentSkyAndAtmosphere()
    for _, child in ipairs(Lighting:GetChildren()) do
        if child.Name:find("^KH_") or child:IsA("Sky") or child:IsA("Atmosphere") then
            if child:IsA("Sky") or child:IsA("Atmosphere") or child:IsA("PostEffect") or child:IsA("ColorCorrectionEffect") or child:IsA("SunRaysEffect") or child:IsA("BloomEffect") then
                child:Destroy()
            end
        end
    end
end

local function ApplyCustomSky(skyName)
    CleanCurrentSkyAndAtmosphere()
    if skyName == "Default" then
        if originalClouds then originalClouds.Parent = Workspace.Terrain end
        if originalSky then
            local s = originalSky:Clone()
            s.Name = "Sky"
            s.Parent = Lighting
        end
        if originalAtmosphere then
            local a = originalAtmosphere:Clone()
            a.Name = "Atmosphere"
            a.Parent = Lighting
        end
        Lighting.ClockTime = originalClockTime
        Lighting.GeographicLatitude = originalGeographicLatitude
        Notify("Visuals", "Default sky restored", 2)
        return
    end
    local fb = fallbackSkyPresets[skyName]
    if fb then
        local newSky = Instance.new("Sky")
        newSky.Name = "KH_CustomSky"
        newSky.SkyboxBk = fb.Bk newSky.SkyboxDn = fb.Dn newSky.SkyboxFt = fb.Ft
        newSky.SkyboxLf = fb.Lf newSky.SkyboxRt = fb.Rt newSky.SkyboxUp = fb.Up
        newSky.CelestialBodiesShown = true
        newSky.Parent = Lighting
        if fb.Atmosphere then
            local newAtm = Instance.new("Atmosphere")
            newAtm.Name = "KH_CustomAtmosphere"
            newAtm.Density = fb.Atmosphere.Density
            newAtm.Offset = fb.Atmosphere.Offset
            newAtm.Color = fb.Atmosphere.Color
            newAtm.Decay = fb.Atmosphere.Decay
            newAtm.Glare = fb.Atmosphere.Glare
            newAtm.Haze = fb.Atmosphere.Haze
            newAtm.Parent = Lighting
        end
        if fb.ClockTime then Lighting.ClockTime = fb.ClockTime end
        Notify("Visuals", "Loaded: " .. skyName, 2)
    end
end

-- ==========================================
-- ESP System
-- ==========================================
local espState = { Biggest = false, Parasite = false, Secret = false }
local espPool = {}

local function ClearESP(tag)
    for i = #espPool, 1, -1 do
        local item = espPool[i]
        if item and (not tag or item.Tag == tag) then
            if item.Highlight then item.Highlight:Destroy() end
            if item.Billboard then item.Billboard:Destroy() end
            table.remove(espPool, i)
        end
    end
end

local function AttachESP(model, tag, color, text)
    for i = 1, #espPool do
        if espPool[i].Model == model and espPool[i].Tag == tag then return end
    end
    local highlight = Instance.new("Highlight")
    highlight.Name = "KH_" .. tag
    highlight.FillColor = color
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    highlight.FillTransparency = 0.45
    highlight.OutlineTransparency = 0
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Adornee = model
    highlight.Parent = ScreenGui

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "KHB_" .. tag
    billboard.Size = UDim2.new(0, 140, 0, 26)
    billboard.StudsOffset = Vector3.new(0, 2.5, 0)
    billboard.AlwaysOnTop = true
    billboard.Adornee = model:IsA("BasePart") and model or (model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart", true))
    billboard.Parent = ScreenGui

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.GothamBold
    label.Text = text
    label.TextColor3 = color
    label.TextStrokeTransparency = 0.2
    label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    label.TextSize = 12
    label.Parent = billboard

    table.insert(espPool, { Model = model, Tag = tag, Highlight = highlight, Billboard = billboard })
end

local function UpdateESP()
    local container = GetEggContainer()
    if not container then return end
    for i = #espPool, 1, -1 do
        local item = espPool[i]
        if item and (not item.Model or not item.Model.Parent) then
            if item.Highlight then item.Highlight:Destroy() end
            if item.Billboard then item.Billboard:Destroy() end
            table.remove(espPool, i)
        end
    end
    local children = container:GetChildren()
    local eggModels = {}
    for i = 1, #children do
        local ch = children[i]
        if ch:IsA("Model") or ch:IsA("BasePart") then
            table.insert(eggModels, ch)
        end
    end
    if espState.Biggest then
        local biggestEgg = nil
        local maxVolume = -1
        for i = 1, #eggModels do
            local vol = GetModelVolume(eggModels[i])
            if vol > maxVolume then maxVolume = vol biggestEgg = eggModels[i] end
        end
        ClearESP("Biggest")
        if biggestEgg and maxVolume > 0 then
            AttachESP(biggestEgg, "Biggest", Color3.fromRGB(180, 140, 255), "★ Biggest Egg ★")
        end
    end
    if espState.Parasite then
        for i = 1, #eggModels do
            if IsParasiteEgg(eggModels[i]) then
                AttachESP(eggModels[i], "Parasite", Color3.fromRGB(200, 50, 50), "⚠ Parasite ⚠")
            end
        end
    end
    if espState.Secret then
        for i = 1, #eggModels do
            if IsSecretEgg(eggModels[i]) then
                AttachESP(eggModels[i], "Secret", Color3.fromRGB(120, 200, 255), "✦ Secret ✦")
            end
        end
    end
end

local espUpdateThread = task.spawn(function()
    while true do
        task.wait(1.5)
        if espState.Biggest or espState.Parasite or espState.Secret then
            pcall(UpdateESP)
        end
    end
end)

-- Visuals UI
AddDropdown(visualsPage, "Custom Sky", {"Default", "NightSky", "SpaceSky", "RealisticSky"}, "Default", function(selectedSky)
    ApplyCustomSky(selectedSky)
end)

AddToggle(visualsPage, "ESP Biggest Egg", "Highlights the largest egg", false, function(state)
    espState.Biggest = state
    if state then UpdateESP() Notify("Visuals", "Biggest Egg ESP on", 2)
    else ClearESP("Biggest") Notify("Visuals", "Biggest Egg ESP off", 2) end
end)

AddToggle(visualsPage, "ESP Parasite Egg", "Highlights parasite eggs", false, function(state)
    espState.Parasite = state
    if state then UpdateESP() Notify("Visuals", "Parasite ESP on", 2)
    else ClearESP("Parasite") Notify("Visuals", "Parasite ESP off", 2) end
end)

AddToggle(visualsPage, "ESP Secret Egg", "Highlights secret eggs", false, function(state)
    espState.Secret = state
    if state then UpdateESP() Notify("Visuals", "Secret ESP on", 2)
    else ClearESP("Secret") Notify("Visuals", "Secret ESP off", 2) end
end)

AddToggle(visualsPage, "Fullbright", "Removes shadows, brightens world", false, function(state)
    if state then
        Lighting.Brightness = 3
        Lighting.ClockTime = 12
        Lighting.FogEnd = 100000
        Notify("Visuals", "Fullbright on", 2)
    else
        Lighting.Brightness = 1
        Lighting.FogEnd = 100000
        Notify("Visuals", "Fullbright off", 2)
    end
end)

-- Player Page
local infiniteJumpConn = nil
AddToggle(playerPage, "Infinite Jump", "Jump continuously mid-air", false, function(state)
    if state then
        if infiniteJumpConn then infiniteJumpConn:Disconnect() end
        infiniteJumpConn = UserInputService.JumpRequest:Connect(function()
            local char = LocalPlayer.Character
            if char then
                local hum = char:FindFirstChildOfClass("Humanoid")
                if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
            end
        end)
        Notify("Player", "Infinite Jump on", 2)
    else
        if infiniteJumpConn then
            infiniteJumpConn:Disconnect()
            infiniteJumpConn = nil
        end
        Notify("Player", "Infinite Jump off", 2)
    end
end)

-- Settings Page
AddButton(settingsPage, "Unload UI", "Disconnects all hooks and destroys GUI", function()
    Notify("diox616 × Nyx", "Unloading...", 1)
    task.wait(0.3)
    autoFarmEnabled = false
    local root = GetRoot()
    if root then root.Anchored = false end
    if espUpdateThread then task.cancel(espUpdateThread) end
    ClearESP()
    ApplyCustomSky("Default")
    if infiniteJumpConn then infiniteJumpConn:Disconnect() end
    ScreenGui:Destroy()
end)

local hintLabel = Instance.new("TextLabel")
hintLabel.Size = UDim2.new(1, 0, 0, 24)
hintLabel.BackgroundTransparency = 1
hintLabel.Text = IS_MOBILE and "Tap ⚡ button to toggle menu" or "RightShift to toggle menu"
hintLabel.TextColor3 = Color3.fromRGB(100, 100, 130)
hintLabel.TextSize = IS_MOBILE and 13 or 11
hintLabel.Font = Enum.Font.Gotham
hintLabel.Parent = settingsPage

print("[diox616 × Nyx] All pages built")

-- ==========================================
-- Floating Toggle Button (Mobile) + RightShift (PC)
-- ==========================================
local isUIVisible = true

if IS_MOBILE then
    local FloatBtn = Instance.new("TextButton")
    FloatBtn.Size = UDim2.new(0, 56, 0, 56)
    FloatBtn.Position = UDim2.new(1, -70, 0, 120)
    FloatBtn.BackgroundColor3 = Color3.fromRGB(120, 80, 200)
    FloatBtn.Text = "⚡"
    FloatBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    FloatBtn.TextSize = 24
    FloatBtn.Parent = ScreenGui

    local floatCorner = Instance.new("UICorner")
    floatCorner.CornerRadius = UDim.new(1, 0)
    floatCorner.Parent = FloatBtn

    local floatStroke = Instance.new("UIStroke")
    floatStroke.Color = Color3.fromRGB(200, 180, 255)
    floatStroke.Thickness = 2
    floatStroke.Parent = FloatBtn

    local floatDragging = false
    local floatDragStart, floatStartPos

    FloatBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            floatDragging = true
            floatDragStart = input.Position
            floatStartPos = FloatBtn.Position
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if floatDragging and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
            local delta = input.Position - floatDragStart
            FloatBtn.Position = UDim2.new(
                math.clamp(floatStartPos.X.Scale + delta.X / ScreenGui.AbsoluteSize.X, 0, 1),
                floatStartPos.X.Offset,
                math.clamp(floatStartPos.Y.Scale + delta.Y / ScreenGui.AbsoluteSize.Y, 0, 1),
                floatStartPos.Y.Offset
            )
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            local totalDelta = (input.Position - floatDragStart).Magnitude
            if totalDelta < 10 then
                isUIVisible = not isUIVisible
                if isUIVisible then
                    MainFrame.Visible = true
                    TweenService:Create(MainFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {BackgroundTransparency = 0.05}):Play()
                    TweenService:Create(MainStroke, TweenInfo.new(0.25), {Transparency = 0}):Play()
                else
                    local tw = TweenService:Create(MainFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {BackgroundTransparency = 1})
                    TweenService:Create(MainStroke, TweenInfo.new(0.25), {Transparency = 1}):Play()
                    tw:Play()
                    tw.Completed:Connect(function()
                        if not isUIVisible then MainFrame.Visible = false end
                    end)
                end
            end
            floatDragging = false
        end
    end)
else
    -- PC: RightShift toggle
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if input.KeyCode == Enum.KeyCode.RightShift then
            isUIVisible = not isUIVisible
            if isUIVisible then
                MainFrame.Visible = true
                TweenService:Create(MainFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {BackgroundTransparency = 0.05}):Play()
                TweenService:Create(MainStroke, TweenInfo.new(0.25), {Transparency = 0}):Play()
            else
                local tw = TweenService:Create(MainFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {BackgroundTransparency = 1})
                TweenService:Create(MainStroke, TweenInfo.new(0.25), {Transparency = 1}):Play()
                tw:Play()
                tw.Completed:Connect(function()
                    if not isUIVisible then MainFrame.Visible = false end
                end)
            end
        end
    end)
end

-- ==========================================
-- Boot Animation
-- ==========================================
MainFrame.Visible = true
MainFrame.BackgroundTransparency = 0.05
MainStroke.Transparency = 0
HeaderDivider.BackgroundTransparency = 0
SidebarDivider.BackgroundTransparency = 0
TitleLabel.TextTransparency = 0
SubtitleLabel.TextTransparency = 0

Notify("diox616 × Nyx", IS_MOBILE and "Loaded on Mobile. Tap ⚡ to toggle." or "Loaded. Press RightShift to toggle.", 3)

print("[diox616 × Nyx] Script fully loaded and UI visible")
