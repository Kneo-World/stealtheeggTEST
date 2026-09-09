--------------------------------------------------------------------------------
-- [KNEO MEGA UTILITY SUITE v3.5] - Advanced Roblox Speed & Interaction Tool
--------------------------------------------------------------------------------
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ProximityPromptService = game:GetService("ProximityPromptService")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

--------------------------------------------------------------------------------
-- 1. CONFIGURATION & STATE MANAGEMENT67
--------------------------------------------------------------------------------
local Config = {
    SpeedHack = false,
    SpeedValue = 500,
    DesyncBypass = false,
    AutoToggleOnInteract = true,
    LoggingEnabled = true,
    SafeModeDelay = 0.15
}

local State = {
    IsPausingForInteraction = false,
    ActivePromptsCount = 0,
    LastTargetName = "None",
    SpeedButtonReference = nil
}

local function KneoLog(message, messageType)
    if not Config.LoggingEnabled then return end
    local prefix = "[Kneo Engine]: "
    if messageType == "WARN" then
        warn(prefix .. message)
    elseif messageType == "ERROR" then
        error(prefix .. message)
    else
        print(prefix .. message)
    end
end

KneoLog("Инициализация тяжелого ядра скрипта...")

--------------------------------------------------------------------------------
-- 2. CAMERA & CHARACTER BYPASS MODULES
--------------------------------------------------------------------------------
local CharacterModule = {}

function CharacterModule.FixCamera()
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
    KneoLog("Камера успешно восстановлена.")
end

function CharacterModule.DeleteHumanoidBypass()
    local char = LocalPlayer.Character
    if not char then 
        KneoLog("Персонаж не найден для Humanoid Bypass!", "WARN")
        return 
    end
    
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then
        for _, v in pairs(char:GetDescendants()) do
            if v:IsA("LocalScript") and v ~= script then
                v.Disabled = true
                v:Destroy()
            end
        end
        hum:Destroy()
        KneoLog("Humanoid успешно уничтожен (Bypass активирован).", "WARN")
    else
        KneoLog("Humanoid уже отсутствует.", "WARN")
    end

    task.wait(0.05)
    CharacterModule.FixCamera()
end

-- Слежение за целостностью камеры
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

--------------------------------------------------------------------------------
-- 3. PROXIMITY PROMPT & INTERACTION HANDLER (SMART BYPASS)
--------------------------------------------------------------------------------
local InteractionModule = {}

function InteractionModule.Init()
    ProximityPromptService.PromptButtonHoldBegan:Connect(function(prompt, player)
        if player == LocalPlayer then
            State.LastTargetName = prompt.Parent and prompt.Parent.Name or "UnknownObject"
            KneoLog(string.format("Начато удержание промпта -> Объект: '%s' | HoldTime: %s", State.LastTargetName, tostring(prompt.HoldDuration)))
            
            if Config.AutoToggleOnInteract and Config.SpeedHack then
                Config.SpeedHack = false
                if State.SpeedButtonReference then
                    State.SpeedButtonReference.BackgroundColor3 = Color3.fromRGB(220, 160, 0) -- Желтый статус (пауза)
                end
                KneoLog("Спидхак автоматически приостановлен на время удержания.")
            end
        end
    end)

    local function RestoreSpeedState()
        if not Config.SpeedHack and Config.AutoToggleOnInteract then
            task.wait(Config.SafeModeDelay)
            Config.SpeedHack = true
            if State.SpeedButtonReference then
                State.SpeedButtonReference.BackgroundColor3 = Color3.fromRGB(90, 50, 220) -- Фиолетовый статус (активен)
            end
            KneoLog("Спидхак возобновлен после взаимодействия.")
        end
    end

    ProximityPromptService.PromptTriggered:Connect(function(prompt, player)
        if player == LocalPlayer then
            KneoLog(string.format("УСПЕХ (Triggered) -> Объект: '%s'", State.LastTargetName))
            RestoreSpeedState()
        end
    end)

    ProximityPromptService.PromptButtonHoldEnded:Connect(function(prompt, player)
        if player == LocalPlayer then
            KneoLog(string.format("ОТМЕНА / СБРОС (HoldEnded) -> Объект: '%s'", State.LastTargetName), "WARN")
            RestoreSpeedState()
        end
    end)
    
    -- Сканер всех промптов в зоне видимости
    task.spawn(function()
        while task.wait(5) do
            local count = 0
            for _, desc in pairs(Workspace:GetDescendants()) do
                if desc:IsA("ProximityPrompt") then
                    count = count + 1
                end
            end
            State.ActivePromptsCount = count
        end
    end)
end

InteractionModule.Init()

--------------------------------------------------------------------------------
-- 4. CFrame ENGINE (HIGH PERFORMANCE SPEEDHACK)
--------------------------------------------------------------------------------
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

--------------------------------------------------------------------------------
-- 5. ADVANCED USER INTERFACE (GUI BUILDER)
--------------------------------------------------------------------------------
local UIModule = {}

function UIModule.Build()
    if CoreGui:FindFirstChild("KneoMegaUtilitySuite") then
        CoreGui.KneoMegaUtilitySuite:Destroy()
    end

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "KneoMegaUtilitySuite"
    ScreenGui.Parent = CoreGui
    ScreenGui.ResetOnSpawn = false

    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Size = UDim2.new(0, 240, 0, 340)
    MainFrame.Position = UDim2.new(0.08, 0, 0.25, 0)
    MainFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
    MainFrame.BorderSizePixel = 0
    MainFrame.Active = true
    MainFrame.Draggable = true
    MainFrame.Parent = ScreenGui

    local UICorner = Instance.new("UICorner")
    UICorner.CornerRadius = UDim.new(0, 10)
    UICorner.Parent = MainFrame

    local UIStroke = Instance.new("UIStroke")
    UIStroke.Color = Color3.fromRGB(70, 40, 150)
    UIStroke.Thickness = 1.5
    UIStroke.Parent = MainFrame

    -- Заголовок
    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Size = UDim2.new(1, -35, 0, 35)
    TitleLabel.Position = UDim2.new(0, 12, 0, 0)
    TitleLabel.Text = "KNEO SUITE // ROBLOX"
    TitleLabel.TextColor3 = Color3.fromRGB(240, 240, 255)
    TitleLabel.Font = Enum.Font.GothamBold
    TitleLabel.TextSize = 12
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Parent = MainFrame

    -- Кнопка закрытия
    local CloseBtn = Instance.new("TextButton")
    CloseBtn.Size = UDim2.new(0, 28, 0, 28)
    CloseBtn.Position = UDim2.new(1, -32, 0, 4)
    CloseBtn.Text = "×"
    CloseBtn.TextColor3 = Color3.fromRGB(160, 160, 180)
    CloseBtn.Font = Enum.Font.GothamBold
    CloseBtn.BackgroundTransparency = 1
    CloseBtn.TextSize = 18
    CloseBtn.Parent = MainFrame
    CloseBtn.MouseButton1Click:Connect(function()
        ScreenGui:Destroy()
        KneoLog("Интерфейс уничтожен пользователем.")
    end)

    -- Информационная строка статуса
    local StatusLabel = Instance.new("TextLabel")
    StatusLabel.Size = UDim2.new(1, -24, 0, 20)
    StatusLabel.Position = UDim2.new(0, 12, 0, 32)
    StatusLabel.Text = "Status: Operational | Target: None"
    StatusLabel.TextColor3 = Color3.fromRGB(100, 220, 120)
    StatusLabel.Font = Enum.Font.Code
    StatusLabel.TextSize = 10
    StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
    StatusLabel.BackgroundTransparency = 1
    StatusLabel.Parent = MainFrame

    -- Обновление статуса в реальном времени
    task.spawn(function()
        while ScreenGui.Parent do
            StatusLabel.Text = string.format("Prompts: %d | Target: %s", State.ActivePromptsCount, State.LastTargetName)
            task.wait(1)
        end
    end)

    -- Поле ввода скорости
    local SpeedBoxLabel = Instance.new("TextLabel")
    SpeedBoxLabel.Size = UDim2.new(0, 110, 0, 30)
    SpeedBoxLabel.Position = UDim2.new(0, 12, 0, 60)
    SpeedBoxLabel.Text = "Velocity Scalar:"
    SpeedBoxLabel.TextColor3 = Color3.fromRGB(180, 180, 200)
    SpeedBoxLabel.Font = Enum.Font.GothamMedium
    SpeedBoxLabel.TextSize = 11
    SpeedBoxLabel.TextXAlignment = Enum.TextXAlignment.Left
    SpeedBoxLabel.BackgroundTransparency = 1
    SpeedBoxLabel.Parent = MainFrame

    local SpeedInput = Instance.new("TextBox")
    SpeedInput.Size = UDim2.new(0, 95, 0, 28)
    SpeedInput.Position = UDim2.new(1, -107, 0, 61)
    SpeedInput.BackgroundColor3 = Color3.fromRGB(28, 28, 38)
    SpeedInput.Text = tostring(Config.SpeedValue)
    SpeedInput.TextColor3 = Color3.fromRGB(0, 255, 160)
    SpeedInput.Font = Enum.Font.GothamBold
    SpeedInput.TextSize = 12
    SpeedInput.Parent = MainFrame

    local boxCorner = Instance.new("UICorner")
    boxCorner.CornerRadius = UDim.new(0, 6)
    boxCorner.Parent = SpeedInput

    SpeedInput.FocusLost:Connect(function()
        local num = tonumber(SpeedInput.Text)
        if num then
            Config.SpeedValue = num
            KneoLog("Установлена новая скорость: " .. tostring(num))
        else
            SpeedInput.Text = tostring(Config.SpeedValue)
        end
    end)

    -- Функция генерации кнопок панели
    local function CreateMenuButton(text, posY, defaultState, callback)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, -24, 0, 32)
        btn.Position = UDim2.new(0, 12, 0, posY)
        btn.BackgroundColor3 = defaultState and Color3.fromRGB(90, 50, 220) or Color3.fromRGB(28, 28, 38)
        btn.Text = text
        btn.TextColor3 = Color3.fromRGB(240, 240, 255)
        btn.Font = Enum.Font.GothamMedium
        btn.TextSize = 11
        btn.Parent = MainFrame

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 6)
        corner.Parent = btn

        local state = defaultState
        btn.MouseButton1Click:Connect(function()
            state = not state
            btn.BackgroundColor3 = state and Color3.fromRGB(90, 50, 220) or Color3.fromRGB(28, 28, 38)
            callback(state)
        end)
        return btn
    end

    -- Добавление функциональных кнопок
    State.SpeedButtonReference = CreateMenuButton("SpeedHack (CFrame Engine)", 100, Config.SpeedHack, function(st)
        Config.SpeedHack = st
    end)

    CreateMenuButton("Bypass: Desync Mode", 140, Config.DesyncBypass, function(st)
        Config.DesyncBypass = st
    end)

    -- Кнопка с мгновенным выполнением (без переключения состояния)
    local function CreateActionItem(text, posY, actionCallback)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, -24, 0, 32)
        btn.Position = UDim2.new(0, 12, 0, posY)
        btn.BackgroundColor3 = Color3.fromRGB(45, 30, 70)
        btn.Text = text
        btn.TextColor3 = Color3.fromRGB(255, 180, 100)
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 11
        btn.Parent = MainFrame

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 6)
        corner.Parent = btn

        btn.MouseButton1Click:Connect(function()
            actionCallback()
        end)
        return btn
    end

    CreateActionItem("Bypass: Delete Humanoid", 180, function()
        CharacterModule.DeleteHumanoidBypass()
    end)

    CreateMenuButton("Smart Auto-Pause (Interaction)", 220, Config.AutoToggleOnInstantly or Config.AutoToggleOnInteract, function(st)
        Config.AutoToggleOnInteract = st
    end)

    CreateMenuButton("Console Logging (F9)", 260, Config.LoggingEnabled, function(st)
        Config.LoggingEnabled = st
    end)
    
    -- Декоративный футер
    local FooterLabel = Instance.new("TextLabel")
    FooterLabel.Size = UDim2.new(1, -24, 0, 20)
    FooterLabel.Position = UDim2.new(0, 12, 1, -24)
    FooterLabel.Text = "Build 2026.09 // Secure Engine"
    FooterLabel.TextColor3 = Color3.fromRGB(90, 90, 110)
    FooterLabel.Font = Enum.Font.Gotham
    FooterLabel.TextSize = 9
    FooterLabel.TextXAlignment = Enum.TextXAlignment.Center
    FooterLabel.BackgroundTransparency = 1
    FooterLabel.Parent = MainFrame
end

UIModule.Build()
KneoLog("Мега-модуль успешно развернут. Ошибки яиц отслеживаются в реальном времени через F9!")
