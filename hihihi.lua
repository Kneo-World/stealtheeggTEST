local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ProximityPromptService = game:GetService("ProximityPromptService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

---------------------------------------------------------
-- Настройки667
---------------------------------------------------------
local Config = {
    SpeedHack = false,
    SpeedValue = 500,
    DesyncBypass = false,
    AutoToggleOnInteract = true
}

local wasSpeedActiveBeforeHold = false
local speedBtnRef = nil

---------------------------------------------------------
-- Фикс Камеры
---------------------------------------------------------
local function fixCamera()
    local char = LocalPlayer.Character
    if not char then return end
    
    local root = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")

    if hum then
        Camera.CameraSubject = hum
    elseif root then
        Camera.CameraSubject = root
    end
    Camera.CameraType = Enum.CameraType.Custom
end

---------------------------------------------------------
-- Bypass Метод: Delete Humanoid (Вернул!)
---------------------------------------------------------
local function deleteHumanoidBypass()
    local char = LocalPlayer.Character
    if not char then return end
    
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then
        for _, v in pairs(char:GetDescendants()) do
            if v:IsA("LocalScript") and v ~= script then
                v.Disabled = true
                v:Destroy()
            end
        end
        hum:Destroy()
    end

    task.wait(0.05)
    fixCamera()
end

RunService.RenderStepped:Connect(function()
    local char = LocalPlayer.Character
    if char then
        local root = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChildOfClass("Humanoid")
        
        if not hum and root and Camera.CameraSubject ~= root then
            Camera.CameraSubject = root
        end
    end
end)

---------------------------------------------------------
-- Умная пауза для зажатия (E)
---------------------------------------------------------
ProximityPromptService.PromptButtonHoldBegan:Connect(function(prompt, player)
    if player == LocalPlayer and Config.AutoToggleOnInteract then
        if Config.SpeedHack then
            wasSpeedActiveBeforeHold = true
            Config.SpeedHack = false
            if speedBtnRef then
                speedBtnRef.BackgroundColor3 = Color3.fromRGB(200, 150, 0) -- Жёлтая во время удержания
            end
        end
    end
end)

local function restoreSpeed()
    if wasSpeedActiveBeforeHold then
        Config.SpeedHack = true
        wasSpeedActiveBeforeHold = false
        if speedBtnRef then
            speedBtnRef.BackgroundColor3 = Color3.fromRGB(80, 50, 200)
        end
    end
end

ProximityPromptService.PromptTriggered:Connect(function(prompt, player)
    if player == LocalPlayer then
        task.wait(0.05)
        restoreSpeed()
    end
end)

ProximityPromptService.PromptButtonHoldEnded:Connect(function(prompt, player)
    if player == LocalPlayer then
        task.wait(0.05)
        restoreSpeed()
    end
end)

---------------------------------------------------------
-- CFrame Speed Engine
---------------------------------------------------------
RunService.Heartbeat:Connect(function(delta)
    if not Config.SpeedHack then return end

    local char = LocalPlayer.Character
    if not char then return end

    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end

    local hum = char:FindFirstChildOfClass("Humanoid")

    if hum and Config.DesyncBypass then
        hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
        hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
        hum:SetStateEnabled(Enum.HumanoidStateType.Climbing, false)
        hum.WalkSpeed = 0
    end

    local moveVector = Vector3.zero
    local camCF = Camera.CFrame
    local forward = Vector3.new(camCF.LookVector.X, 0, camCF.LookVector.Z)
    local right = Vector3.new(camCF.RightVector.X, 0, camCF.RightVector.Z)

    if forward.Magnitude > 0 then forward = forward.Unit end
    if right.Magnitude > 0 then right = right.Unit end

    if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveVector = moveVector + forward end
    if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveVector = moveVector - forward end
    if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveVector = moveVector - right end
    if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveVector = moveVector + right end

    if moveVector.Magnitude > 0 then
        moveVector = moveVector.Unit
        root.CFrame = root.CFrame + (moveVector * (Config.SpeedValue * delta))
        root.AssemblyLinearVelocity = Vector3.zero
    end
end)

---------------------------------------------------------
-- GUI
---------------------------------------------------------
if CoreGui:FindFirstChild("MiniSpeedGui") then
    CoreGui.MiniSpeedGui:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MiniSpeedGui"
ScreenGui.Parent = CoreGui

local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Size = UDim2.new(0, 220, 0, 270)
Main.Position = UDim2.new(0.05, 0, 0.3, 0)
Main.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
Main.BorderSizePixel = 0
Main.Active = true
Main.Draggable = true
Main.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 8)
UICorner.Parent = Main

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -30, 0, 30)
Title.Position = UDim2.new(0, 10, 0, 0)
Title.Text = "Speed Hack & Bypass"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 13
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.BackgroundTransparency = 1
Title.Parent = Main

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 25, 0, 25)
CloseBtn.Position = UDim2.new(1, -28, 0, 3)
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(180, 180, 180)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.BackgroundTransparency = 1
CloseBtn.TextSize = 12
CloseBtn.Parent = Main
CloseBtn.MouseButton1Click:Connect(function() ScreenGui:Destroy() end)

local function CreateButton(text, posY, defaultState, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -20, 0, 30)
    btn.Position = UDim2.new(0, 10, 0, posY)
    btn.BackgroundColor3 = defaultState and Color3.fromRGB(80, 50, 200) or Color3.fromRGB(35, 35, 45)
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamMedium
    btn.TextSize = 11
    btn.Parent = Main

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = btn

    local state = defaultState
    btn.MouseButton1Click:Connect(function()
        state = not state
        btn.BackgroundColor3 = state and Color3.fromRGB(80, 50, 200) or Color3.fromRGB(35, 35, 45)
        callback(state)
    end)
    return btn
end

-- Input Speed
local SpeedBoxLabel = Instance.new("TextLabel")
SpeedBoxLabel.Size = UDim2.new(0, 100, 0, 28)
SpeedBoxLabel.Position = UDim2.new(0, 10, 0, 35)
SpeedBoxLabel.Text = "Custom Speed:"
SpeedBoxLabel.TextColor3 = Color3.fromRGB(200, 200, 210)
SpeedBoxLabel.Font = Enum.Font.GothamMedium
SpeedBoxLabel.TextSize = 11
SpeedBoxLabel.TextXAlignment = Enum.TextXAlignment.Left
SpeedBoxLabel.BackgroundTransparency = 1
SpeedBoxLabel.Parent = Main

local SpeedInput = Instance.new("TextBox")
SpeedInput.Size = UDim2.new(0, 90, 0, 28)
SpeedInput.Position = UDim2.new(1, -100, 0, 35)
SpeedInput.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
SpeedInput.Text = tostring(Config.SpeedValue)
SpeedInput.TextColor3 = Color3.fromRGB(0, 255, 150)
SpeedInput.Font = Enum.Font.GothamBold
SpeedInput.TextSize = 12
SpeedInput.Parent = Main

local boxCorner = Instance.new("UICorner")
boxCorner.CornerRadius = UDim.new(0, 6)
boxCorner.Parent = SpeedInput

SpeedInput.FocusLost:Connect(function()
    local num = tonumber(SpeedInput.Text)
    if num then
        Config.SpeedValue = num
    else
        SpeedInput.Text = tostring(Config.SpeedValue)
    end
end)

-- Buttons
speedBtnRef = CreateButton("SpeedHack (CFrame)", 70, Config.SpeedHack, function(st)
    Config.SpeedHack = st
end)

CreateButton("Bypass: Desync Mode", 110, Config.DesyncBypass, function(st)
    Config.DesyncBypass = st
end)

CreateButton("Bypass: Delete Humanoid", 150, false, function(st)
    if st then
        deleteHumanoidBypass()
    end
end)

CreateButton("Auto Hold-Pause (Smart)", 190, Config.AutoToggleOnInteract, function(st)
    Config.AutoToggleOnInteract = st
end)
