local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

---------------------------------------------------------
-- Настройки
---------------------------------------------------------
local Config = {
    SpeedHack = false,
    SpeedValue = 120, -- Рекомендуется не ставить больше 100-150 для ивентов
    SafeDelivery = true,
    MinDeliveryTime = 4.5 -- Минимальное время (в сек) между взятием и сдачей
}

local eggGrabTime = 0
local isDelivering = false

---------------------------------------------------------
-- Фикс Камеры
---------------------------------------------------------
local function fixCamera()
    local char = LocalPlayer.Character
    if not char then return end
    
    local hum = char:FindFirstChildOfClass("Humanoid")
    local root = char:FindFirstChild("HumanoidRootPart")

    if hum then
        Camera.CameraSubject = hum
    elseif root then
        Camera.CameraSubject = root
    end
    Camera.CameraType = Enum.CameraType.Custom
end

---------------------------------------------------------
-- Безопасный CFrame Speed
---------------------------------------------------------
RunService.Heartbeat:Connect(function(delta)
    if not Config.SpeedHack then return end

    local char = LocalPlayer.Character
    if not char then return end

    local root = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not root or not hum then return end

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
    end
end)

---------------------------------------------------------
-- Безопасный триггер с учётом таймера сервера
---------------------------------------------------------
local function safeInteract(prompt)
    if isDelivering then return end
    isDelivering = true

    local currentTime = tick()
    local timePassed = currentTime - eggGrabTime

    -- Если с момента подбора прошло мало времени, выжидаем паузу
    if Config.SafeDelivery and timePassed < Config.MinDeliveryTime then
        local waitTime = Config.MinDeliveryTime - timePassed
        task.wait(waitTime)
    end

    -- Активируем промпт
    if fireproximityprompt then
        fireproximityprompt(prompt)
    else
        prompt:InputHoldBegin()
        task.wait(0.05)
        prompt:InputHoldEnd()
    end

    eggGrabTime = tick() -- Обновляем время
    task.wait(0.5)
    isDelivering = false
end

-- Отслеживание нажатий ProximityPrompt
workspace.DescendantAdded:Connect(function(descendant)
    if descendant:IsA("ProximityPrompt") then
        descendant.Triggered:Connect(function(player)
            if player == LocalPlayer then
                eggGrabTime = tick()
            end
        end)
    end
end)

---------------------------------------------------------
-- Простой интерфейс
---------------------------------------------------------
if CoreGui:FindFirstChild("EggBypassGui") then
    CoreGui.EggBypassGui:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "EggBypassGui"
ScreenGui.Parent = CoreGui

local Main = Instance.new("Frame")
Main.Size = UDim2.new(0, 200, 0, 180)
Main.Position = UDim2.new(0.05, 0, 0.3, 0)
Main.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
Main.Active = true
Main.Draggable = true
Main.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 8)
UICorner.Parent = Main

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 30)
Title.Text = "Safe Egg Delivery"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 12
Title.BackgroundTransparency = 1
Title.Parent = Main

local function CreateToggle(text, posY, defaultState, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -20, 0, 32)
    btn.Position = UDim2.new(0, 10, 0, posY)
    btn.BackgroundColor3 = defaultState and Color3.fromRGB(60, 140, 70) or Color3.fromRGB(40, 40, 50)
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
        btn.BackgroundColor3 = state and Color3.fromRGB(60, 140, 70) or Color3.fromRGB(40, 40, 50)
        callback(state)
    end)
end

CreateToggle("SpeedHack (Safe)", 40, Config.SpeedHack, function(st)
    Config.SpeedHack = st
end)

CreateToggle("Auto Delay Bypass", 80, Config.SafeDelivery, function(st)
    Config.SafeDelivery = st
end)

local FixCamBtn = Instance.new("TextButton")
FixCamBtn.Size = UDim2.new(1, -20, 0, 32)
FixCamBtn.Position = UDim2.new(0, 10, 0, 125)
FixCamBtn.BackgroundColor3 = Color3.fromRGB(50, 80, 160)
FixCamBtn.Text = "Fix Camera"
FixCamBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
FixCamBtn.Font = Enum.Font.GothamMedium
FixCamBtn.TextSize = 11
FixCamBtn.Parent = Main

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 6)
corner.Parent = FixCamBtn

FixCamBtn.MouseButton1Click:Connect(fixCamera)
