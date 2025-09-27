-- LocalScript (StarterPlayerScripts)
-- ADVANCED Mobile Aimbot/Camlock with Professional Smoothing

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Stats = game:GetService("Stats")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- Only run on mobile
if not UserInputService.TouchEnabled then
    return
end

-- Advanced Settings
local Settings = {
    AimLock = {
        Enabled = false,
        Smoothness = 0.85,
        Prediction = 0.165,
        TargetPart = "Head",
        Acceleration = 1.2,
        MaxTurnSpeed = 15,
        EasingStyle = "Exponential"
    },
    CamLock = {
        Enabled = false,
        Smoothness = 0.75,
        Prediction = 0.185,
        Acceleration = 1.35,
        MaxTurnSpeed = 12,
        Shake = false,
        ShakeIntensity = 2,
        EasingStyle = "Sine"
    },
    MaxDistance = 180,
    WallCheck = true,
    TeamCheck = false,
    AntiDetection = {
        Enabled = true,
        Randomization = 0.08,
        HumanizeDelay = true,
        SmoothTransitions = true
    }
}

local target = nil
local connections = {}
local lastUpdateTime = 0
local smoothingData = {
    lastPosition = Vector3.new(),
    velocity = Vector3.new(),
    acceleration = Vector3.new()
}

-- Get network ping for advanced prediction
local function getPing()
    local ping = Stats.Network.ServerStatsItem["Data Ping"]:GetValue()
    return math.max(ping, 20) / 1000 -- Convert to seconds, minimum 20ms
end

-- Advanced easing functions
local EasingFunctions = {
    Exponential = function(t) return t == 0 and 0 or 2^(10 * (t - 1)) end,
    Sine = function(t) return -math.cos(t * (math.pi / 2)) + 1 end,
    Cubic = function(t) return t^3 end,
    Quartic = function(t) return t^4 end,
    Back = function(t) 
        local c1, c3 = 1.70158, 2.70158
        return c3 * t^3 - c1 * t^2
    end
}

-- Multi-layer smoothing algorithm
local function advancedSmooth(currentPos, targetPos, smoothness, easing, deltaTime, maxSpeed)
    local distance = (targetPos - currentPos).Magnitude
    local direction = (targetPos - currentPos).Unit
    
    -- Distance-based acceleration
    local accelerationFactor = math.min(distance / 50, 2)
    local dynamicSmoothness = smoothness * accelerationFactor
    
    -- Apply easing function
    local easingFunc = EasingFunctions[easing] or EasingFunctions.Exponential
    local easedSmoothness = easingFunc(dynamicSmoothness)
    
    -- Speed limiting
    local maxDelta = maxSpeed * deltaTime
    local desiredDelta = direction * math.min(distance * easedSmoothness, maxDelta)
    
    -- Anti-detection randomization
    if Settings.AntiDetection.Enabled then
        local randomOffset = Vector3.new(
            (math.random() - 0.5) * Settings.AntiDetection.Randomization,
            (math.random() - 0.5) * Settings.AntiDetection.Randomization,
            (math.random() - 0.5) * Settings.AntiDetection.Randomization
        )
        desiredDelta = desiredDelta + randomOffset
    end
    
    return currentPos + desiredDelta
end

-- Enhanced prediction system
local function advancedPrediction(targetHRP, predictionStrength)
    local velocity = targetHRP.AssemblyLinearVelocity
    local ping = getPing()
    
    -- Multi-factor prediction
    local basePrediction = velocity * predictionStrength
    local pingCompensation = velocity * ping
    local accelerationPrediction = Vector3.new()
    
    -- Calculate acceleration if we have previous data
    local currentTime = tick()
    if smoothingData.lastPosition ~= Vector3.new() then
        local timeDelta = currentTime - lastUpdateTime
        if timeDelta > 0 then
            local currentVelocity = (targetHRP.Position - smoothingData.lastPosition) / timeDelta
            smoothingData.acceleration = (currentVelocity - smoothingData.velocity) / timeDelta
            accelerationPrediction = smoothingData.acceleration * (predictionStrength * 0.5)
            smoothingData.velocity = currentVelocity
        end
    end
    
    smoothingData.lastPosition = targetHRP.Position
    lastUpdateTime = currentTime
    
    return basePrediction + pingCompensation + accelerationPrediction
end

-- Improved wall check with ray casting
local function hasLineOfSight(origin, destination)
    if not Settings.WallCheck then return true end
    
    local direction = destination - origin
    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = {player.Character, target}
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    raycastParams.IgnoreWater = true
    
    local raycast = workspace:Raycast(origin, direction, raycastParams)
    return raycast == nil
end

-- Target functions
local function getCharacter()
    return player.Character
end

local function getClosestPlayer()
    local character = getCharacter()
    if not character or not character:FindFirstChild("HumanoidRootPart") then
        return nil
    end

    local hrp = character.HumanoidRootPart
    local closest = nil
    local shortestDistance = Settings.MaxDistance

    for _, v in pairs(Players:GetPlayers()) do
        if v ~= player and v.Character and v.Character:FindFirstChild("HumanoidRootPart") then
            local enemyHrp = v.Character.HumanoidRootPart
            local enemyHumanoid = v.Character:FindFirstChildOfClass("Humanoid")
            
            if enemyHumanoid and enemyHumanoid.Health > 0 then
                local distance = (hrp.Position - enemyHrp.Position).Magnitude
                
                if distance < shortestDistance then
                    if not Settings.TeamCheck or v.Team ~= player.Team then
                        if hasLineOfSight(hrp.Position, enemyHrp.Position) then
                            shortestDistance = distance
                            closest = v.Character
                        end
                    end
                end
            end
        end
    end

    return closest
end

-- Create the minimizable UI
local function createUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "MobileLockUI"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = player:WaitForChild("PlayerGui")

    -- Small circular button (minimized state)
    local miniButton = Instance.new("TextButton")
    miniButton.Name = "MiniButton"
    miniButton.Size = UDim2.new(0, 50, 0, 50)
    miniButton.Position = UDim2.new(0, 20, 0.5, -25)
    miniButton.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    miniButton.BorderSizePixel = 0
    miniButton.Text = "🎯"
    miniButton.TextColor3 = Color3.new(1, 1, 1)
    miniButton.TextSize = 20
    miniButton.Font = Enum.Font.GothamBold
    miniButton.Visible = false
    miniButton.Parent = screenGui

    local miniCorner = Instance.new("UICorner")
    miniCorner.CornerRadius = UDim.new(0.5, 0)
    miniCorner.Parent = miniButton

    local miniStroke = Instance.new("UIStroke")
    miniStroke.Color = Color3.fromRGB(100, 100, 100)
    miniStroke.Thickness = 2
    miniStroke.Parent = miniButton

    -- Main frame (expanded state)
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 150, 0, 180)
    mainFrame.Position = UDim2.new(0, 20, 0.5, -90)
    mainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    mainFrame.BorderSizePixel = 0
    mainFrame.Visible = true
    mainFrame.Parent = screenGui

    local frameCorner = Instance.new("UICorner")
    frameCorner.CornerRadius = UDim.new(0, 12)
    frameCorner.Parent = mainFrame

    local frameStroke = Instance.new("UIStroke")
    frameStroke.Color = Color3.fromRGB(80, 80, 80)
    frameStroke.Thickness = 1
    frameStroke.Parent = mainFrame

    -- Header
    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, 0, 0, 35)
    header.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    header.BorderSizePixel = 0
    header.Parent = mainFrame

    local headerCorner = Instance.new("UICorner")
    headerCorner.CornerRadius = UDim.new(0, 12)
    headerCorner.Parent = header

    local headerFix = Instance.new("Frame")
    headerFix.Size = UDim2.new(1, 0, 0.5, 0)
    headerFix.Position = UDim2.new(0, 0, 0.5, 0)
    headerFix.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    headerFix.BorderSizePixel = 0
    headerFix.Parent = header

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -30, 1, 0)
    title.Position = UDim2.new(0, 5, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "LOCK PRO"
    title.TextColor3 = Color3.new(1, 1, 1)
    title.TextSize = 14
    title.Font = Enum.Font.GothamBold
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = header

    local minimizeBtn = Instance.new("TextButton")
    minimizeBtn.Size = UDim2.new(0, 25, 0, 25)
    minimizeBtn.Position = UDim2.new(1, -30, 0, 5)
    minimizeBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    minimizeBtn.BorderSizePixel = 0
    minimizeBtn.Text = "−"
    minimizeBtn.TextColor3 = Color3.new(1, 1, 1)
    minimizeBtn.TextSize = 16
    minimizeBtn.Font = Enum.Font.GothamBold
    minimizeBtn.Parent = header

    local minimizeBtnCorner = Instance.new("UICorner")
    minimizeBtnCorner.CornerRadius = UDim.new(0.5, 0)
    minimizeBtnCorner.Parent = minimizeBtn

    -- Status
    local status = Instance.new("TextLabel")
    status.Size = UDim2.new(1, -10, 0, 20)
    status.Position = UDim2.new(0, 5, 0, 40)
    status.BackgroundTransparency = 1
    status.Text = "READY"
    status.TextColor3 = Color3.fromRGB(100, 255, 100)
    status.TextSize = 12
    status.Font = Enum.Font.Gotham
    status.TextXAlignment = Enum.TextXAlignment.Center
    status.Parent = mainFrame

    -- Aimlock button
    local aimlockBtn = Instance.new("TextButton")
    aimlockBtn.Size = UDim2.new(1, -10, 0, 40)
    aimlockBtn.Position = UDim2.new(0, 5, 0, 65)
    aimlockBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    aimlockBtn.BorderSizePixel = 0
    aimlockBtn.Text = "AIMLOCK"
    aimlockBtn.TextColor3 = Color3.new(1, 1, 1)
    aimlockBtn.TextSize = 14
    aimlockBtn.Font = Enum.Font.GothamBold
    aimlockBtn.Parent = mainFrame

    local aimlockCorner = Instance.new("UICorner")
    aimlockCorner.CornerRadius = UDim.new(0, 8)
    aimlockCorner.Parent = aimlockBtn

    -- Camlock button
    local camlockBtn = Instance.new("TextButton")
    camlockBtn.Size = UDim2.new(1, -10, 0, 40)
    camlockBtn.Position = UDim2.new(0, 5, 0, 110)
    camlockBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    camlockBtn.BorderSizePixel = 0
    camlockBtn.Text = "CAMLOCK"
    camlockBtn.TextColor3 = Color3.new(1, 1, 1)
    camlockBtn.TextSize = 14
    camlockBtn.Font = Enum.Font.GothamBold
    camlockBtn.Parent = mainFrame

    local camlockCorner = Instance.new("UICorner")
    camlockCorner.CornerRadius = UDim.new(0, 8)
    camlockCorner.Parent = camlockBtn

    -- Minimize/Maximize functionality
    local isMinimized = false

    local function minimize()
        if isMinimized then return end
        isMinimized = true
        
        local shrinkTween = TweenService:Create(
            mainFrame,
            TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In),
            {Size = UDim2.new(0, 0, 0, 0)}
        )
        
        shrinkTween:Play()
        shrinkTween.Completed:Wait()
        
        mainFrame.Visible = false
        miniButton.Visible = true
        miniButton.Size = UDim2.new(0, 0, 0, 0)
        
        local growTween = TweenService:Create(
            miniButton,
            TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
            {Size = UDim2.new(0, 50, 0, 50)}
        )
        
        growTween:Play()
    end

    local function maximize()
        if not isMinimized then return end
        isMinimized = false
        
        local shrinkTween = TweenService:Create(
            miniButton,
            TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.In),
            {Size = UDim2.new(0, 0, 0, 0)}
        )
        
        shrinkTween:Play()
        shrinkTween.Completed:Wait()
        
        miniButton.Visible = false
        mainFrame.Visible = true
        mainFrame.Size = UDim2.new(0, 0, 0, 0)
        
        local growTween = TweenService:Create(
            mainFrame,
            TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
            {Size = UDim2.new(0, 150, 0, 180)}
        )
        
        growTween:Play()
    end

    minimizeBtn.Activated:Connect(minimize)
    miniButton.Activated:Connect(maximize)

    return {
        gui = screenGui,
        mainFrame = mainFrame,
        miniButton = miniButton,
        status = status,
        aimlockBtn = aimlockBtn,
        camlockBtn = camlockBtn
    }
end

local ui = createUI()

-- Update UI status
local function updateStatus()
    if Settings.AimLock.Enabled then
        ui.status.Text = "🎯 AIM LOCKED"
        ui.status.TextColor3 = Color3.fromRGB(255, 200, 0)
        ui.aimlockBtn.BackgroundColor3 = Color3.fromRGB(255, 200, 0)
        ui.camlockBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    elseif Settings.CamLock.Enabled then
        ui.status.Text = "📹 CAM LOCKED"
        ui.status.TextColor3 = Color3.fromRGB(0, 200, 255)
        ui.camlockBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 255)
        ui.aimlockBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    else
        ui.status.Text = "READY"
        ui.status.TextColor3 = Color3.fromRGB(100, 255, 100)
        ui.aimlockBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        ui.camlockBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    end
end

-- Stop all locks
local function stopLocks()
    Settings.AimLock.Enabled = false
    Settings.CamLock.Enabled = false
    target = nil
    
    -- Reset smoothing data
    smoothingData.lastPosition = Vector3.new()
    smoothingData.velocity = Vector3.new()
    smoothingData.acceleration = Vector3.new()
    
    for _, connection in pairs(connections) do
        connection:Disconnect()
    end
    connections = {}
    
    local character = getCharacter()
    if character and character:FindFirstChildOfClass("Humanoid") then
        character.Humanoid.AutoRotate = true
    end
    
    updateStatus()
end

-- Advanced aimlock with professional smoothing
local function startAimlock()
    stopLocks()
    
    target = getClosestPlayer()
    if not target then
        ui.status.Text = "NO TARGET"
        ui.status.TextColor3 = Color3.fromRGB(255, 100, 100)
        task.wait(1)
        updateStatus()
        return
    end

    Settings.AimLock.Enabled = true
    
    local character = getCharacter()
    if character and character:FindFirstChildOfClass("Humanoid") then
        character.Humanoid.AutoRotate = false
    end

    local lastTime = tick()
    connections.aimlock = RunService.RenderStepped:Connect(function()
        local character = getCharacter()
        if not character or not character:FindFirstChild("HumanoidRootPart") then
            stopLocks()
            return
        end

        if not target or not target:FindFirstChild("HumanoidRootPart") then
            target = getClosestPlayer()
            if not target then
                stopLocks()
                return
            end
        end

        local hrp = character.HumanoidRootPart
        local targetHrp = target.HumanoidRootPart
        local targetPart = target:FindFirstChild(Settings.AimLock.TargetPart) or targetHrp

        -- Advanced prediction
        local predictionVector = advancedPrediction(targetHrp, Settings.AimLock.Prediction)
        local predictedPosition = targetPart.Position + predictionVector

        -- Current time for delta calculations
        local currentTime = tick()
        local deltaTime = currentTime - lastTime
        lastTime = currentTime

        -- Advanced smoothing with professional algorithm
        local currentLookDirection = hrp.CFrame.LookVector
        local currentPosition = hrp.Position
        local targetDirection = (Vector3.new(predictedPosition.X, currentPosition.Y, predictedPosition.Z) - currentPosition).Unit
        
        local smoothedDirection = advancedSmooth(
            currentLookDirection,
            targetDirection,
            Settings.AimLock.Smoothness,
            Settings.AimLock.EasingStyle,
            deltaTime,
            Settings.AimLock.MaxTurnSpeed
        )
        
        local newCFrame = CFrame.new(currentPosition, currentPosition + smoothedDirection)
        hrp.CFrame = newCFrame
    end)

    updateStatus()
end

-- Advanced camlock with shake and professional smoothing
local function startCamlock()
    stopLocks()
    
    target = getClosestPlayer()
    if not target then
        ui.status.Text = "NO TARGET"
        ui.status.TextColor3 = Color3.fromRGB(255, 100, 100)
        task.wait(1)
        updateStatus()
        return
    end

    Settings.CamLock.Enabled = true

    local lastTime = tick()
    connections.camlock = RunService.RenderStepped:Connect(function()
        if not target or not target:FindFirstChild("HumanoidRootPart") then
            target = getClosestPlayer()
            if not target then
                stopLocks()
                return
            end
        end

        local targetHrp = target.HumanoidRootPart
        local targetPart = target:FindFirstChild(Settings.AimLock.TargetPart) or targetHrp

        -- Advanced prediction
        local predictionVector = advancedPrediction(targetHrp, Settings.CamLock.Prediction)
        local predictedPosition = targetPart.Position + predictionVector

        -- Add camera shake if enabled
        if Settings.CamLock.Shake then
            local shakeX = (math.random() - 0.5) * Settings.CamLock.ShakeIntensity
            local shakeY = (math.random() - 0.5) * Settings.CamLock.ShakeIntensity
            local shakeZ = (math.random() - 0.5) * Settings.CamLock.ShakeIntensity
            predictedPosition = predictedPosition + Vector3.new(shakeX, shakeY, shakeZ)
        end

        -- Current time for delta calculations
        local currentTime = tick()
        local deltaTime = currentTime - lastTime
        lastTime = currentTime

        -- Advanced camera smoothing
        local currentCameraPosition = camera.CFrame.Position
        local currentLookDirection = camera.CFrame.LookVector
        local targetDirection = (predictedPosition - currentCameraPosition).Unit
        
        local smoothedDirection = advancedSmooth(
            currentLookDirection,
            targetDirection,
            Settings.CamLock.Smoothness,
            Settings.CamLock.EasingStyle,
            deltaTime,
            Settings.CamLock.MaxTurnSpeed
        )
        
        local newCFrame = CFrame.new(currentCameraPosition, currentCameraPosition + smoothedDirection)
        camera.CFrame = newCFrame
    end)

    updateStatus()
end

-- Button connections
ui.aimlockBtn.Activated:Connect(function()
    if Settings.AimLock.Enabled then
        stopLocks()
    else
        startAimlock()
    end
end)

ui.camlockBtn.Activated:Connect(function()
    if Settings.CamLock.Enabled then
        stopLocks()
    else
        startCamlock()
    end
end)

-- Make UI draggable
local dragging = false
local dragInput, mousePos, framePos

local function updateDrag(input)
    local delta = input.Position - mousePos
    ui.mainFrame.Position = UDim2.new(framePos.X.Scale, framePos.X.Offset + delta.X, framePos.Y.Scale, framePos.Y.Offset + delta.Y)
end

ui.mainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        mousePos = input.Position
        framePos = ui.mainFrame.Position
        
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch and dragging then
        updateDrag(input)
    end
end)

-- Initialize
updateStatus()

print("Advanced Mobile Lock System loaded!")
print("Features: Professional Smoothing, Advanced Prediction, Anti-Detection")
