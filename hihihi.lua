local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

---------------------------------------------------------
-- 1. Configuration & State
---------------------------------------------------------
local Config = {
    SpeedHackEnabled = false,
    SpeedValue = 70.0,
    SafeMode = true,             -- Безопасный режим для кражи яиц
    AutoGrabEggs = false,         -- Авто-забор яиц через ProximityPrompt
    AutoSlowNearEgg = true,       -- Снижать скорость рядом с яйцом
    BypassEnabled = false
}

---------------------------------------------------------
-- 2. Helper Functions (Egg & Prompt Finder)
---------------------------------------------------------
-- Поиск ближайшего ProximityPrompt (кнопки забора яйца)
local function getNearestPrompt()
    local character = LocalPlayer.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then return nil end
    local rootPos = character.HumanoidRootPart.Position

    local closestPrompt = nil
    local closestDistance = math.huge

    for _, desc in pairs(workspace:GetDescendants()) do
        if desc:IsA("ProximityPrompt") and desc.Enabled then
            local parentPart = desc.Parent
            if parentPart and parentPart:IsA("BasePart") then
                local dist = (parentPart.Position - rootPos).Magnitude
                if dist < closestDistance then
                    closestDistance = dist
                    closestPrompt = desc
                end
            end
        end
    end
    return closestPrompt, closestDistance
end

---------------------------------------------------------
-- 3. CFrame SpeedHack Logic
---------------------------------------------------------
RunService.RenderStepped:Connect(function(delta)
    if not Config.SpeedHackEnabled then return end

    local character = LocalPlayer.Character
    if not character then return end

    local rootPart = character:FindFirstChild("HumanoidRootPart")
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not rootPart then return end

    -- Определение итоговой скорости
    local currentSpeed = Config.SpeedValue
    if Config.SafeMode and currentSpeed > 60 then
        currentSpeed = 60 -- Ограничение безопасности для защиты от ошибки
    end

    -- Авто-замедление при приближении к яйцу (если ближе 20 studs)
    if Config.AutoSlowNearEgg then
        local _, dist = getNearestPrompt()
        if dist and dist < 20 then
            currentSpeed = math.min(currentSpeed, 25) -- Сервер успеет зарегистрировать персонажа
        end
    end

    local moveVector = Vector3.new(0, 0, 0)
    local camCFrame = Camera.CFrame

    local forward = Vector3.new(camCFrame.LookVector.X, 0, camCFrame.LookVector.Z)
    local right = Vector3.new(camCFrame.RightVector.X, 0, camCFrame.RightVector.Z)

    if forward.Magnitude > 0 then forward = forward.Unit end
    if right.Magnitude > 0 then right = right.Unit end

    if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveVector = moveVector + forward end
    if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveVector = moveVector - forward end
    if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveVector = moveVector - right end
    if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveVector = moveVector + right end

    if moveVector.Magnitude > 0 then
        moveVector = moveVector.Unit
        rootPart.CFrame = rootPart.CFrame + (moveVector * (currentSpeed * delta))

        if humanoid and humanoid.FloorMaterial ~= Enum.Material.Air then
            rootPart.AssemblyLinearVelocity = Vector3.new(0, rootPart.AssemblyLinearVelocity.Y, 0)
        end
    end
end)

---------------------------------------------------------
-- 4. Auto Grab Proximity Prompts Loop
---------------------------------------------------------
task.spawn(function()
    while task.wait(0.1) do
        if Config.AutoGrabEggs then
            local prompt, dist = getNearestPrompt()
            if prompt and dist and dist <= (prompt.MaxActivationDistance or 15) then
                if fireproximityprompt then
                    fireproximityprompt(prompt)
                else
                    prompt:InputHoldBegin()
                    task.wait(prompt.HoldDuration or 0.1)
                    prompt:InputHoldEnd()
                end
            end
        end
    end
end)

---------------------------------------------------------
-- 5. Tween Teleport Function
---------------------------------------------------------
local function tweenToNearestEgg()
    local prompt, dist = getNearestPrompt()
    if not prompt or not prompt.Parent then return end

    local character = LocalPlayer.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then return end

    local targetPart = prompt.Parent
    local targetCFrame = targetPart.CFrame * CFrame.new(0, 2, 3)

    -- Расчет времени задержки для безопасности сервера (1 секунда на каждые 100 блоков)
    local flyTime = math.clamp(dist / 80, 0.8, 4)

    local tweenInfo = TweenInfo.new(flyTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local tween = TweenService:Create(character.HumanoidRootPart, tweenInfo, {CFrame = targetCFrame})
    tween:Play()

    tween.Completed:Connect(function()
        task.wait(0.2)
        if fireproximityprompt then
            fireproximityprompt(prompt)
        end
    end)
end

---------------------------------------------------------
-- 6. UI Construction (KerryHub Premium)
---------------------------------------------------------
if CoreGui:FindFirstChild("KerryHub_PremiumUI") then
    CoreGui.KerryHub_PremiumUI:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "KerryHub_PremiumUI"
ScreenGui.Parent = CoreGui
ScreenGui.ResetOnSpawn = false

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 520, 0, 380)
MainFrame.Position = UDim2.new(0.5, -260, 0.5, -190)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 16, 22)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 12)
MainCorner.Parent = MainFrame

-- Header
local Header = Instance.new("Frame")
Header.Size = UDim2.new(1, 0, 0, 50)
Header.BackgroundTransparency = 1
Header.Parent = MainFrame

local Title = Instance.new("TextLabel")
Title.Position = UDim2.new(0, 20, 0, 10)
Title.Size = UDim2.new(0, 200, 0, 20)
Title.Text = "KerryHub"
Title.TextColor3 = Color3.fromRGB(240, 240, 245)
Title.TextSize = 16
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.BackgroundTransparency = 1
Title.Parent = Header

local SubTitle = Instance.new("TextLabel")
SubTitle.Position = UDim2.new(0, 20, 0, 28)
SubTitle.Size = UDim2.new(0, 200, 0, 15)
SubTitle.Text = "Egg Steal Fix Edition"
SubTitle.TextColor3 = Color3.fromRGB(120, 100, 255)
SubTitle.TextSize = 11
SubTitle.Font = Enum.Font.Gotham
SubTitle.TextXAlignment = Enum.TextXAlignment.Left
SubTitle.BackgroundTransparency = 1
SubTitle.Parent = Header

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 20, 0, 20)
CloseBtn.Position = UDim2.new(1, -30, 0, 15)
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = Color3.fromRGB(120, 122, 135)
CloseBtn.BackgroundTransparency = 1
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 14
CloseBtn.Parent = Header
CloseBtn.MouseButton1Click:Connect(function() ScreenGui:Destroy() end)

-- Sidebar
local Sidebar = Instance.new("Frame")
Sidebar.Size = UDim2.new(0, 140, 1, -50)
Sidebar.Position = UDim2.new(0, 0, 0, 50)
Sidebar.BackgroundTransparency = 1
Sidebar.Parent = MainFrame

local function CreateTabButton(name, posY, isActive)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -20, 0, 36)
    btn.Position = UDim2.new(0, 10, 0, posY)
    btn.BackgroundColor3 = isActive and Color3.fromRGB(25, 26, 35) or Color3.fromRGB(0, 0, 0)
    btn.BackgroundTransparency = isActive and 0 or 1
    btn.Text = "    " .. name
    btn.TextColor3 = isActive and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(130, 132, 145)
    btn.Font = Enum.Font.GothamMedium
    btn.TextSize = 13
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.Parent = Sidebar

    local bCorner = Instance.new("UICorner")
    bCorner.CornerRadius = UDim.new(0, 8)
    bCorner.Parent = btn
    return btn
end

CreateTabButton("Movement", 0, true)
CreateTabButton("Egg Stealer", 42, false)
CreateTabButton("Settings", 84, false)

-- Content Area
local Content = Instance.new("Frame")
Content.Size = UDim2.new(1, -150, 1, -60)
Content.Position = UDim2.new(0, 140, 0, 50)
Content.BackgroundTransparency = 1
Content.Parent = MainFrame

---------------------------------------------------------
-- UI Components
---------------------------------------------------------
local function CreateToggleCard(parent, title, subText, posY, defaultState, callback)
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, -10, 0, 55)
    card.Position = UDim2.new(0, 0, 0, posY)
    card.BackgroundColor3 = Color3.fromRGB(20, 21, 28)
    card.Parent = parent

    local cCorner = Instance.new("UICorner")
    cCorner.CornerRadius = UDim.new(0, 8)
    cCorner.Parent = card

    local tLabel = Instance.new("TextLabel")
    tLabel.Position = UDim2.new(0, 12, 0, 10)
    tLabel.Size = UDim2.new(1, -70, 0, 18)
    tLabel.Text = title
    tLabel.TextColor3 = Color3.fromRGB(230, 230, 235)
    tLabel.Font = Enum.Font.GothamBold
    tLabel.TextSize = 13
    tLabel.TextXAlignment = Enum.TextXAlignment.Left
    tLabel.BackgroundTransparency = 1
    tLabel.Parent = card

    local sLabel = Instance.new("TextLabel")
    sLabel.Position = UDim2.new(0, 12, 0, 28)
    sLabel.Size = UDim2.new(1, -70, 0, 15)
    sLabel.Text = subText
    sLabel.TextColor3 = Color3.fromRGB(100, 102, 115)
    sLabel.Font = Enum.Font.Gotham
    sLabel.TextSize = 10
    sLabel.TextXAlignment = Enum.TextXAlignment.Left
    sLabel.BackgroundTransparency = 1
    sLabel.Parent = card

    local switch = Instance.new("TextButton")
    switch.Size = UDim2.new(0, 42, 0, 22)
    switch.Position = UDim2.new(1, -52, 0.5, -11)
    switch.BackgroundColor3 = defaultState and Color3.fromRGB(120, 80, 255) or Color3.fromRGB(35, 36, 48)
    switch.Text = ""
    switch.Parent = card

    local swCorner = Instance.new("UICorner")
    swCorner.CornerRadius = UDim.new(1, 0)
    swCorner.Parent = switch

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 16, 0, 16)
    knob.Position = defaultState and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    knob.Parent = switch

    local kCorner = Instance.new("UICorner")
    kCorner.CornerRadius = UDim.new(1, 0)
    kCorner.Parent = knob

    local enabled = defaultState
    switch.MouseButton1Click:Connect(function()
        enabled = not enabled
        local targetPos = enabled and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
        local targetColor = enabled and Color3.fromRGB(120, 80, 255) or Color3.fromRGB(35, 36, 48)

        TweenService:Create(knob, TweenInfo.new(0.15), {Position = targetPos}):Play()
        TweenService:Create(switch, TweenInfo.new(0.15), {BackgroundColor3 = targetColor}):Play()

        callback(enabled)
    end)
end

local function CreateSliderCard(parent, title, minVal, maxVal, defaultVal, posY, callback)
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, -10, 0, 65)
    card.Position = UDim2.new(0, 0, 0, posY)
    card.BackgroundColor3 = Color3.fromRGB(20, 21, 28)
    card.Parent = parent

    local cCorner = Instance.new("UICorner")
    cCorner.CornerRadius = UDim.new(0, 8)
    cCorner.Parent = card

    local tLabel = Instance.new("TextLabel")
    tLabel.Position = UDim2.new(0, 12, 0, 10)
    tLabel.Size = UDim2.new(0, 150, 0, 18)
    tLabel.Text = title
    tLabel.TextColor3 = Color3.fromRGB(230, 230, 235)
    tLabel.Font = Enum.Font.GothamBold
    tLabel.TextSize = 13
    tLabel.TextXAlignment = Enum.TextXAlignment.Left
    tLabel.BackgroundTransparency = 1
    tLabel.Parent = card

    local valLabel = Instance.new("TextLabel")
    valLabel.Position = UDim2.new(1, -90, 0, 10)
    valLabel.Size = UDim2.new(0, 80, 0, 18)
    valLabel.Text = string.format("%.1f", defaultVal)
    valLabel.TextColor3 = Color3.fromRGB(140, 110, 255)
    valLabel.Font = Enum.Font.GothamBold
    valLabel.TextSize = 13
    valLabel.TextXAlignment = Enum.TextXAlignment.Right
    valLabel.BackgroundTransparency = 1
    valLabel.Parent = card

    local track = Instance.new("Frame")
    track.Size = UDim2.new(1, -24, 0, 4)
    track.Position = UDim2.new(0, 12, 0, 42)
    track.BackgroundColor3 = Color3.fromRGB(35, 36, 48)
    track.BorderSizePixel = 0
    track.Parent = card

    local trCorner = Instance.new("UICorner")
    trCorner.CornerRadius = UDim.new(1, 0)
    trCorner.Parent = track

    local fill = Instance.new("Frame")
    local startRatio = (defaultVal - minVal) / (maxVal - minVal)
    fill.Size = UDim2.new(startRatio, 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(120, 80, 255)
    fill.BorderSizePixel = 0
    fill.Parent = track

    local fCorner = Instance.new("UICorner")
    fCorner.CornerRadius = UDim.new(1, 0)
    fCorner.Parent = fill

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 12, 0, 12)
    knob.Position = UDim2.new(1, -6, 0.5, -6)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    knob.Parent = fill

    local kCorner = Instance.new("UICorner")
    kCorner.CornerRadius = UDim.new(1, 0)
    kCorner.Parent = knob

    local dragging = false
    local function UpdateInput(input)
        local posX = math.clamp(input.Position.X - track.AbsolutePosition.X, 0, track.AbsoluteSize.X)
        local ratio = posX / track.AbsoluteSize.X
        local value = minVal + (ratio * (maxVal - minVal))
        fill.Size = UDim2.new(ratio, 0, 1, 0)
        valLabel.Text = string.format("%.1f", value)
        callback(value)
    end

    track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            UpdateInput(input)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            UpdateInput(input)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
end

local function CreateButtonCard(parent, title, buttonText, posY, callback)
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, -10, 0, 50)
    card.Position = UDim2.new(0, 0, 0, posY)
    card.BackgroundColor3 = Color3.fromRGB(20, 21, 28)
    card.Parent = parent

    local cCorner = Instance.new("UICorner")
    cCorner.CornerRadius = UDim.new(0, 8)
    cCorner.Parent = card

    local tLabel = Instance.new("TextLabel")
    tLabel.Position = UDim2.new(0, 12, 0, 15)
    tLabel.Size = UDim2.new(0, 200, 0, 18)
    tLabel.Text = title
    tLabel.TextColor3 = Color3.fromRGB(230, 230, 235)
    tLabel.Font = Enum.Font.GothamBold
    tLabel.TextSize = 13
    tLabel.TextXAlignment = Enum.TextXAlignment.Left
    tLabel.BackgroundTransparency = 1
    tLabel.Parent = card

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 110, 0, 28)
    btn.Position = UDim2.new(1, -120, 0.5, -14)
    btn.BackgroundColor3 = Color3.fromRGB(120, 80, 255)
    btn.Text = buttonText
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 11
    btn.Parent = card

    local bCorner = Instance.new("UICorner")
    bCorner.CornerRadius = UDim.new(0, 6)
    bCorner.Parent = btn

    btn.MouseButton1Click:Connect(callback)
end

---------------------------------------------------------
-- Populating Controls
---------------------------------------------------------
CreateToggleCard(Content, "CFrame SpeedHack", "Smooth movement speed", 0, Config.SpeedHackEnabled, function(state)
    Config.SpeedHackEnabled = state
end)

CreateSliderCard(Content, "Speed Value", 16, 1000, Config.SpeedValue, 60, function(value)
    Config.SpeedValue = value
end)

CreateToggleCard(Content, "Auto-Slow Near Egg (Anti-Error)", "Slows down near eggs so server accepts it", 130, Config.AutoSlowNearEgg, function(state)
    Config.AutoSlowNearEgg = state
end)

CreateToggleCard(Content, "Auto-Grab Eggs (Bypass E)", "Auto activates egg ProximityPrompts", 190, Config.AutoGrabEggs, function(state)
    Config.AutoGrabEggs = state
end)

CreateButtonCard(Content, "Safe Tween To Nearest Egg", "Fly To Egg", 250, function()
    tweenToNearestEgg()
end)
