local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

---------------------------------------------------------
-- 1. Настройки (Config)
---------------------------------------------------------
local Config = {
    BypassEnabled = false,
    SpeedHackEnabled = false,
    MovementSpeed = 50, -- Начальная скорость (можно менять через GUI)
    
    EspEnabled = false,
    
    AutoFarmEnabled = false,
    SelectedEggType = "Biggest Egg",
    SelectedZone = "All Zones"
}

---------------------------------------------------------
-- 2. AntiCheat Bypass + Ultra Smooth Movement
---------------------------------------------------------
local function ApplyNoHumanoidBypass()
    local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local rootPart = character:WaitForChild("HumanoidRootPart")
    local humanoid = character:FindFirstChildOfClass("Humanoid")

    if humanoid then
        Camera.CameraSubject = rootPart
        humanoid:Destroy()
        print("[Bypass] Humanoid удален, камера зафиксирована на RootPart.")
    end
end

-- Плавное и стабильное передвижение без застревания в полу
RunService.RenderStepped:Connect(function(delta)
    if not Config.SpeedHackEnabled then return end
    
    local character = LocalPlayer.Character
    if not character then return end
    
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end

    local moveVector = Vector3.new(0, 0, 0)
    local camCFrame = Camera.CFrame

    -- Берем плоские векторы направления (без оси Y, чтобы не уходить под землю)
    local forward = Vector3.new(camCFrame.LookVector.X, 0, camCFrame.LookVector.Z).Unit
    local right = Vector3.new(camCFrame.RightVector.X, 0, camCFrame.RightVector.Z).Unit

    if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveVector = moveVector + forward end
    if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveVector = moveVector - forward end
    if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveVector = moveVector - right end
    if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveVector = moveVector + right end

    if moveVector.Magnitude > 0 then
        moveVector = moveVector.Unit
        rootPart.CFrame = rootPart.CFrame + (moveVector * (Config.MovementSpeed * delta))
    end
end)

---------------------------------------------------------
-- 3. ESP System
---------------------------------------------------------
local function CreateHighlight(targetModel, color)
    local oldHL = targetModel:FindFirstChild("EggESP_Highlight")
    if oldHL then oldHL:Destroy() end

    local highlight = Instance.new("Highlight")
    highlight.Name = "EggESP_Highlight"
    highlight.FillColor = color
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    highlight.FillTransparency = 0.4
    highlight.OutlineTransparency = 0
    highlight.Adornee = targetModel
    highlight.Parent = targetModel
end

local function HasFXEffect(model)
    for _, desc in ipairs(model:GetDescendants()) do
        if desc.Name == "fx" or desc:IsA("ParticleEmitter") or desc:IsA("Beam") or desc:IsA("Sparkles") or desc:IsA("Fire") or desc:IsA("PointLight") then
            return true
        end
    end
    return false
end

local function ProcessEggsESP()
    if not Config.EspEnabled then return end
    
    local eggFolder = workspace:FindFirstChild("AreaEggSlotsClient", true)
    if not eggFolder then return end

    local biggestEgg = nil
    local maxVolume = 0

    for _, eggModel in ipairs(eggFolder:GetChildren()) do
        if eggModel:IsA("Model") then
            local success, size = pcall(function() return eggModel:GetExtentsSize() end)
            if success and size then
                local volume = size.X * size.Y * size.Z
                if volume > maxVolume then
                    maxVolume = volume
                    biggestEgg = eggModel
                end
            end

            if eggModel:FindFirstChild("MonsterParasiteVisual", true) then
                CreateHighlight(eggModel, Color3.fromRGB(255, 0, 0))
            elseif HasFXEffect(eggModel) then
                CreateHighlight(eggModel, Color3.fromRGB(255, 0, 255))
            end
        end
    end

    if biggestEgg and not biggestEgg:FindFirstChild("EggESP_Highlight") then
        CreateHighlight(biggestEgg, Color3.fromRGB(255, 215, 0))
    end
end

task.spawn(function()
    while true do
        pcall(ProcessEggsESP)
        task.wait(2)
    end
end)

---------------------------------------------------------
-- 4. Auto Farm System
---------------------------------------------------------
local function GetSortedZones()
    local zones = {}
    local ground = workspace:FindFirstChild("Ground", true)
    
    local signs = {}
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj.Name == "RequiredSpeedSign" then
            table.insert(signs, obj)
        end
    end

    if ground and #signs > 0 then
        table.sort(signs, function(a, b)
            local posA = a:IsA("Model") and a:GetPrimaryPartCFrame().Position or a.Position
            local posB = b:IsA("Model") and b:GetPrimaryPartCFrame().Position or b.Position
            local gPos = ground:IsA("Model") and ground:GetPrimaryPartCFrame().Position or ground.Position
            return (posA - gPos).Magnitude < (posB - gPos).Magnitude
        end)

        for idx, sign in ipairs(signs) do
            zones["Zone " .. idx] = sign
        end
    end
    return zones
end

local function GetEggZone(eggModel, zones)
    local eggPos = eggModel:IsA("Model") and eggModel:GetPrimaryPartCFrame().Position or eggModel.Position
    local closestZone = "Zone 1"
    local minDistance = math.huge

    for zoneName, signObj in pairs(zones) do
        local signPos = signObj:IsA("Model") and signObj:GetPrimaryPartCFrame().Position or signObj.Position
        local dist = (eggPos - signPos).Magnitude
        if dist < minDistance then
            minDistance = dist
            closestZone = zoneName
        end
    end
    return closestZone
end

local function GetTargetEgg()
    local eggFolder = workspace:FindFirstChild("AreaEggSlotsClient", true)
    if not eggFolder then return nil end

    local zones = GetSortedZones()
    local candidates = {}

    for _, eggModel in ipairs(eggFolder:GetChildren()) do
        if eggModel:IsA("Model") and eggModel:FindFirstChildWhichIsA("ProximityPrompt", true) then
            local eggZone = GetEggZone(eggModel, zones)
            if Config.SelectedZone == "All Zones" or Config.SelectedZone == eggZone then
                table.insert(candidates, eggModel)
            end
        end
    end

    if #candidates == 0 then return nil end

    if Config.SelectedEggType == "Parasite Egg" then
        for _, egg in ipairs(candidates) do
            if egg:FindFirstChild("MonsterParasiteVisual", true) then return egg end
        end
    elseif Config.SelectedEggType == "Secret Egg" then
        for _, egg in ipairs(candidates) do
            if HasFXEffect(egg) then return egg end
        end
    elseif Config.SelectedEggType == "Biggest Egg" then
        local biggestEgg = nil
        local maxVolume = 0
        for _, egg in ipairs(candidates) do
            local success, size = pcall(function() return egg:GetExtentsSize() end)
            if success and size then
                local volume = size.X * size.Y * size.Z
                if volume > maxVolume then
                    maxVolume = volume
                    biggestEgg = egg
                end
            end
        end
        return biggestEgg
    end

    return nil
end

local function FlyToTarget(targetPosition)
    local character = LocalPlayer.Character
    if not character then return false end
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return false end

    while Config.AutoFarmEnabled do
        local currentPos = rootPart.Position
        local distance = (targetPosition - currentPos).Magnitude
        
        if distance < 4 then break end

        local direction = (targetPosition - currentPos).Unit
        rootPart.CFrame = rootPart.CFrame + (direction * (Config.MovementSpeed * RunService.RenderStepped:Wait()))
    end
    return true
end

task.spawn(function()
    while true do
        if Config.AutoFarmEnabled then
            local targetEgg = GetTargetEgg()

            if targetEgg and targetEgg.Parent then
                local prompt = targetEgg:FindFirstChildWhichIsA("ProximityPrompt", true)
                local eggPos = targetEgg:GetPrimaryPartCFrame().Position

                if prompt and eggPos then
                    FlyToTarget(eggPos)

                    if targetEgg.Parent and prompt then
                        prompt.HoldDuration = 0
                        fireproximityprompt(prompt)
                        task.wait(0.2)
                    end

                    local ground = workspace:FindFirstChild("Ground", true)
                    if ground then
                        local groundPos = ground:IsA("Model") and ground:GetPrimaryPartCFrame().Position or ground.Position
                        FlyToTarget(groundPos)
                        task.wait(0.3)
                    end
                end
            end
        end
        task.wait(0.3)
    end
end)

---------------------------------------------------------
-- 5. GUI Interface (KerryHub Style + Speed Box)
---------------------------------------------------------
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "KerryHub_Fixed"
ScreenGui.Parent = CoreGui
ScreenGui.ResetOnSpawn = false

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 480, 0, 310)
MainFrame.Position = UDim2.new(0.5, -240, 0.5, -155)
MainFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 10)
UICorner.Parent = MainFrame

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -20, 0, 40)
Title.Position = UDim2.new(0, 15, 0, 0)
Title.Text = "KerryHub | Steal An Egg [Fixed]"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 18
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.BackgroundTransparency = 1
Title.Parent = MainFrame

local Sidebar = Instance.new("Frame")
Sidebar.Size = UDim2.new(0, 120, 1, -50)
Sidebar.Position = UDim2.new(0, 10, 0, 45)
Sidebar.BackgroundColor3 = Color3.fromRGB(24, 24, 30)
Sidebar.Parent = MainFrame

local SidebarCorner = Instance.new("UICorner")
SidebarCorner.CornerRadius = UDim.new(0, 8)
SidebarCorner.Parent = Sidebar

local Content = Instance.new("Frame")
Content.Size = UDim2.new(1, -150, 1, -50)
Content.Position = UDim2.new(0, 140, 0, 45)
Content.BackgroundTransparency = 1
Content.Parent = MainFrame

local function CreateTabButton(name, positionY)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -10, 0, 32)
    btn.Position = UDim2.new(0, 5, 0, positionY)
    btn.BackgroundColor3 = Color3.fromRGB(30, 30, 38)
    btn.Text = name
    btn.TextColor3 = Color3.fromRGB(200, 200, 200)
    btn.Font = Enum.Font.GothamMedium
    btn.TextSize = 13
    btn.Parent = Sidebar
    
    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 6)
    btnCorner.Parent = btn
    return btn
end

local TabMovementBtn = CreateTabButton("Movement", 10)
local TabVisualsBtn = CreateTabButton("Visuals", 48)
local TabAutoFarmBtn = CreateTabButton("Auto Farm", 86)

local PageMovement = Instance.new("Frame")
PageMovement.Size = UDim2.new(1, 0, 1, 0)
PageMovement.BackgroundTransparency = 1
PageMovement.Parent = Content

local PageVisuals = Instance.new("Frame")
PageVisuals.Size = UDim2.new(1, 0, 1, 0)
PageVisuals.BackgroundTransparency = 1
PageVisuals.Visible = false
PageVisuals.Parent = Content

local PageAutoFarm = Instance.new("Frame")
PageAutoFarm.Size = UDim2.new(1, 0, 1, 0)
PageAutoFarm.BackgroundTransparency = 1
PageAutoFarm.Visible = false
PageAutoFarm.Parent = Content

TabMovementBtn.MouseButton1Click:Connect(function()
    PageMovement.Visible = true; PageVisuals.Visible = false; PageAutoFarm.Visible = false
end)

TabVisualsBtn.MouseButton1Click:Connect(function()
    PageMovement.Visible = false; PageVisuals.Visible = true; PageAutoFarm.Visible = false
end)

TabAutoFarmBtn.MouseButton1Click:Connect(function()
    PageMovement.Visible = false; PageVisuals.Visible = false; PageAutoFarm.Visible = true
end)

local function CreateToggle(parent, text, posY, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 35)
    frame.Position = UDim2.new(0, 0, 0, posY)
    frame.BackgroundColor3 = Color3.fromRGB(24, 24, 30)
    frame.Parent = parent

    local fCorner = Instance.new("UICorner")
    fCorner.CornerRadius = UDim.new(0, 6)
    fCorner.Parent = frame

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -50, 1, 0)
    label.Position = UDim2.new(0, 10, 0, 0)
    label.Text = text
    label.TextColor3 = Color3.fromRGB(220, 220, 220)
    label.Font = Enum.Font.Gotham
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.BackgroundTransparency = 1
    label.Parent = frame

    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Size = UDim2.new(0, 40, 0, 20)
    toggleBtn.Position = UDim2.new(1, -50, 0.5, -10)
    toggleBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
    toggleBtn.Text = ""
    toggleBtn.Parent = frame

    local tCorner = Instance.new("UICorner")
    tCorner.CornerRadius = UDim.new(1, 0)
    tCorner.Parent = toggleBtn

    local enabled = false
    toggleBtn.MouseButton1Click:Connect(function()
        enabled = not enabled
        toggleBtn.BackgroundColor3 = enabled and Color3.fromRGB(120, 90, 255) or Color3.fromRGB(50, 50, 60)
        callback(enabled)
    end)
end

local function CreateButton(parent, text, posY, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 35)
    btn.Position = UDim2.new(0, 0, 0, posY)
    btn.BackgroundColor3 = Color3.fromRGB(120, 90, 255)
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 13
    btn.Parent = parent

    local bCorner = Instance.new("UICorner")
    bCorner.CornerRadius = UDim.new(0, 6)
    bCorner.Parent = btn

    btn.MouseButton1Click:Connect(callback)
    return btn
end

-- Ввод своей скорости (Input Box)
local function CreateSpeedInput(parent, posY)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 35)
    frame.Position = UDim2.new(0, 0, 0, posY)
    frame.BackgroundColor3 = Color3.fromRGB(24, 24, 30)
    frame.Parent = parent

    local fCorner = Instance.new("UICorner")
    fCorner.CornerRadius = UDim.new(0, 6)
    fCorner.Parent = frame

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0, 150, 1, 0)
    label.Position = UDim2.new(0, 10, 0, 0)
    label.Text = "Speed Value:"
    label.TextColor3 = Color3.fromRGB(220, 220, 220)
    label.Font = Enum.Font.Gotham
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.BackgroundTransparency = 1
    label.Parent = frame

    local textBox = Instance.new("TextBox")
    textBox.Size = UDim2.new(0, 80, 0, 25)
    textBox.Position = UDim2.new(1, -90, 0.5, -12)
    textBox.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
    textBox.Text = tostring(Config.MovementSpeed)
    textBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    textBox.Font = Enum.Font.GothamBold
    textBox.TextSize = 13
    textBox.Parent = frame

    local boxCorner = Instance.new("UICorner")
    boxCorner.CornerRadius = UDim.new(0, 4)
    boxCorner.Parent = textBox

    textBox.FocusLost:Connect(function()
        local num = tonumber(textBox.Text)
        if num then
            Config.MovementSpeed = num
            print("[Movement] Скорость изменена на: " .. num)
        else
            textBox.Text = tostring(Config.MovementSpeed)
        end
    end)
end

---------------------------------------------------------
-- Заполнение страниц
---------------------------------------------------------
CreateButton(PageMovement, "AntiCheat Bypass (Remove Humanoid)", 0, function()
    ApplyNoHumanoidBypass()
end)

CreateToggle(PageMovement, "CFrame SpeedHack", 45, function(state)
    Config.SpeedHackEnabled = state
end)

CreateSpeedInput(PageMovement, 90) -- Поле ввода скорости

CreateToggle(PageVisuals, "ESP Eggs (Biggest / Parasite / Secret)", 0, function(state)
    Config.EspEnabled = state
end)

CreateToggle(PageAutoFarm, "Auto Farm Eggs", 0, function(state)
    Config.AutoFarmEnabled = state
end)

local eggBtn = CreateButton(PageAutoFarm, "Type: Biggest Egg", 45, function() end)
eggBtn.MouseButton1Click:Connect(function()
    if Config.SelectedEggType == "Biggest Egg" then
        Config.SelectedEggType = "Parasite Egg"
    elseif Config.SelectedEggType == "Parasite Egg" then
        Config.SelectedEggType = "Secret Egg"
    else
        Config.SelectedEggType = "Biggest Egg"
    end
    eggBtn.Text = "Type: " .. Config.SelectedEggType
end)

local zoneBtn = CreateButton(PageAutoFarm, "Zone: All Zones", 90, function() end)
zoneBtn.MouseButton1Click:Connect(function()
    if Config.SelectedZone == "All Zones" then
        Config.SelectedZone = "Zone 1"
    elseif Config.SelectedZone == "Zone 1" then
        Config.SelectedZone = "Zone 2"
    elseif Config.SelectedZone == "Zone 2" then
        Config.SelectedZone = "Zone 3"
    else
        Config.SelectedZone = "All Zones"
    end
    zoneBtn.Text = "Zone: " .. Config.SelectedZone
end)
