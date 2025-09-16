-- LocalScript (StarterPlayerScripts)
-- Mobile-Only Enhanced Lock-On System with Aim Lock & Camlock

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local character, humanoid, hrp

-- Mobile platform check
local function isMobile()
    return UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
end

-- Exit if not on mobile
if not isMobile() then
    return
end

-- Lock system configuration
local Config = {
    MAX_DISTANCE = 100,
    AIM_SMOOTHNESS = 0.18,
    CAM_SMOOTHNESS = 0.15,
    PREDICTION_STRENGTH = 0.35,
    WALL_CHECK = true,
    STICKY_LOCK = true,
    SWITCH_DISTANCE = 20,
    GUI_SCALE = 1.2 -- Larger for mobile
}

-- Lock modes
local LockModes = {
    NONE = 0,
    AIM_LOCK = 1,
    CAM_LOCK = 2
}

-- Current state
local currentMode = LockModes.NONE
local lockTarget = nil
local lockBillboard = nil
local connections = {}

-- Character setup
local function setupCharacter(char)
    character = char
    humanoid = char:WaitForChild("Humanoid")
    hrp = char:FindFirstChild("HumanoidRootPart") or char:WaitForChild("HumanoidRootPart")
    if humanoid then 
        humanoid.AutoRotate = true 
    end
end

if player.Character then 
    setupCharacter(player.Character) 
end
player.CharacterAdded:Connect(setupCharacter)

-- Mobile GUI Creation with touch optimization
local function createMobileGUI()
    local gui = Instance.new("ScreenGui")
    gui.Name = "MobileLockOnUI"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.Parent = player:WaitForChild("PlayerGui")

    -- Main frame - positioned for thumb access
    local frame = Instance.new("Frame")
    frame.Name = "LockFrame"
    frame.Size = UDim2.new(0, 160 * Config.GUI_SCALE, 0, 240 * Config.GUI_SCALE)
    frame.Position = UDim2.new(0, 20, 0.3, 0)
    frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    frame.BorderSizePixel = 0
    frame.Active = true
    frame.Parent = gui

    -- Add corner rounding and stroke
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = frame

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(60, 60, 60)
    stroke.Thickness = 2
    stroke.Parent = frame

    -- Title with mobile-friendly size
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, 0, 0, 35 * Config.GUI_SCALE)
    title.Position = UDim2.new(0, 0, 0, 0)
    title.Text = "🎯 LOCK SYSTEM"
    title.TextColor3 = Color3.new(1, 1, 1)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBold
    title.TextSize = 16 * Config.GUI_SCALE
    title.Parent = frame

    -- Status label
    local status = Instance.new("TextLabel")
    status.Name = "Status"
    status.Size = UDim2.new(1, -10, 0, 25 * Config.GUI_SCALE)
    status.Position = UDim2.new(0, 5, 0, 35 * Config.GUI_SCALE)
    status.Text = "READY"
    status.TextColor3 = Color3.fromRGB(100, 255, 100)
    status.BackgroundTransparency = 1
    status.Font = Enum.Font.Gotham
    status.TextSize = 12 * Config.GUI_SCALE
    status.TextXAlignment = Enum.TextXAlignment.Center
    status.Parent = frame

    -- Aim Lock Button - larger for touch
    local aimBtn = Instance.new("TextButton")
    aimBtn.Name = "AimLockBtn"
    aimBtn.Size = UDim2.new(1, -15, 0, 50 * Config.GUI_SCALE)
    aimBtn.Position = UDim2.new(0, 7.5, 0, 70 * Config.GUI_SCALE)
    aimBtn.Text = "🎯 AIM LOCK"
    aimBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    aimBtn.TextColor3 = Color3.new(1, 1, 1)
    aimBtn.Font = Enum.Font.GothamBold
    aimBtn.TextSize = 16 * Config.GUI_SCALE
    aimBtn.AutoButtonColor = false
    aimBtn.Parent = frame

    local aimCorner = Instance.new("UICorner")
    aimCorner.CornerRadius = UDim.new(0, 8)
    aimCorner.Parent = aimBtn

    -- Camlock Button
    local camBtn = Instance.new("TextButton")
    camBtn.Name = "CamlockBtn"
    camBtn.Size = UDim2.new(1, -15, 0, 50 * Config.GUI_SCALE)
    camBtn.Position = UDim2.new(0, 7.5, 0, 130 * Config.GUI_SCALE)
    camBtn.Text = "📹 CAMLOCK"
    camBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    camBtn.TextColor3 = Color3.new(1, 1, 1)
    camBtn.Font = Enum.Font.GothamBold
    camBtn.TextSize = 16 * Config.GUI_SCALE
    camBtn.AutoButtonColor = false
    camBtn.Parent = frame

    local camCorner = Instance.new("UICorner")
    camCorner.CornerRadius = UDim.new(0, 8)
    camCorner.Parent = camBtn

    -- Unlock Button
    local unlockBtn = Instance.new("TextButton")
    unlockBtn.Name = "UnlockBtn"
    unlockBtn.Size = UDim2.new(1, -15, 0, 45 * Config.GUI_SCALE)
    unlockBtn.Position = UDim2.new(0, 7.5, 0, 190 * Config.GUI_SCALE)
    unlockBtn.Text = "❌ UNLOCK"
    unlockBtn.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
    unlockBtn.TextColor3 = Color3.new(1, 1, 1)
    unlockBtn.Font = Enum.Font.GothamBold
    unlockBtn.TextSize = 15 * Config.GUI_SCALE
    unlockBtn.AutoButtonColor = false
    unlockBtn.Parent = frame

    local unlockCorner = Instance.new("UICorner")
    unlockCorner.CornerRadius = UDim.new(0, 8)
    unlockCorner.Parent = unlockBtn

    -- Touch feedback for buttons
    local function addTouchFeedback(button, activeColor)
        local originalColor = button.BackgroundColor3
        
        button.TouchTap:Connect(function()
            button.BackgroundColor3 = activeColor or Color3.fromRGB(255, 255, 255)
            wait(0.1)
            button.BackgroundColor3 = originalColor
        end)
    end

    addTouchFeedback(aimBtn, Color3.fromRGB(100, 255, 100))
    addTouchFeedback(camBtn, Color3.fromRGB(100, 255, 255))
    addTouchFeedback(unlockBtn, Color3.fromRGB(255, 100, 100))

    -- Mobile drag functionality
    local dragging = false
    local dragStart = nil
    local startPos = nil

    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.Touch then
            local delta = input.Position - dragStart
            local newX = math.clamp(startPos.X.Offset + delta.X, 0, gui.AbsoluteSize.X - frame.AbsoluteSize.X)
            local newY = math.clamp(startPos.Y.Offset + delta.Y, 0, gui.AbsoluteSize.Y - frame.AbsoluteSize.Y)
            
            frame.Position = UDim2.new(0, newX, 0, newY)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    return frame, aimBtn, camBtn, unlockBtn, status
end

local mainFrame, aimLockBtn, camlockBtn, unlockBtn, statusLabel = createMobileGUI()

-- Billboard management with mobile-optimized size
local function detachBillboard()
    if lockBillboard then
        lockBillboard:Destroy()
        lockBillboard = nil
    end
end

local function attachBillboard(model, mode)
    detachBillboard()
    local targetHRP = model:FindFirstChild("HumanoidRootPart")
    if not targetHRP then return end

    local bb = Instance.new("BillboardGui")
    bb.Size = UDim2.new(0, 180, 0, 60) -- Larger for mobile
    bb.StudsOffset = Vector3.new(0, 4, 0)
    bb.AlwaysOnTop = true
    bb.Parent = targetHRP

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    frame.BackgroundTransparency = 0.2
    frame.Parent = bb

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = frame

    local stroke = Instance.new("UIStroke")
    stroke.Color = mode == LockModes.AIM_LOCK and Color3.fromRGB(255, 165, 0) or Color3.fromRGB(0, 255, 255)
    stroke.Thickness = 3
    stroke.Parent = frame

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = mode == LockModes.AIM_LOCK and "🎯 LOCKED ON" or "📹 CAM LOCKED"
    label.TextScaled = true
    label.Font = Enum.Font.GothamBold
    label.TextColor3 = mode == LockModes.AIM_LOCK and Color3.fromRGB(255, 200, 0) or Color3.fromRGB(100, 255, 255)
    label.Parent = frame

    -- Pulsing effect
    local pulseInfo = TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
    local pulseTween = TweenService:Create(stroke, pulseInfo, {Transparency = 0.3})
    pulseTween:Play()

    lockBillboard = bb
end

-- Target validation
local function isValidTarget(model)
    if not model or not model:IsA("Model") then return false end
    local hum = model:FindFirstChildWhichIsA("Humanoid")
    local part = model:FindFirstChild("HumanoidRootPart")
    if not hum or not part or hum.Health <= 0 then return false end
    if model == character then return false end
    local targetPlayer = Players:GetPlayerFromCharacter(model)
    if targetPlayer == player then return false end
    return true
end

-- Enhanced raycast wall check for mobile
local function hasLineOfSight(from, to)
    if not Config.WALL_CHECK then return true end
    
    local direction = (to - from)
    local raycast = workspace:Raycast(from, direction, {
        FilterType = Enum.RaycastFilterType.Blacklist,
        FilterDescendantsInstances = {character, lockTarget}
    })
    
    return raycast == nil
end

-- Mobile-optimized target finding
local function getNearestTarget()
    if not hrp then return nil end
    
    local nearest = nil
    local shortestDistance = Config.MAX_DISTANCE
    local cameraLookDirection = camera.CFrame.LookVector
    
    -- Check all players first (prioritized for mobile PvP)
    for _, otherPlayer in ipairs(Players:GetPlayers()) do
        if otherPlayer ~= player and otherPlayer.Character and isValidTarget(otherPlayer.Character) then
            local targetHRP = otherPlayer.Character.HumanoidRootPart
            local distance = (hrp.Position - targetHRP.Position).Magnitude
            
            if distance < shortestDistance then
                local directionToTarget = (targetHRP.Position - hrp.Position).Unit
                local dotProduct = cameraLookDirection:Dot(directionToTarget)
                
                -- More lenient angle for mobile (easier targeting)
                if dotProduct > 0.1 and hasLineOfSight(hrp.Position, targetHRP.Position) then
                    shortestDistance = distance
                    nearest = otherPlayer.Character
                end
            end
        end
    end
    
    -- Check NPCs if no players found
    if not nearest then
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("Model") and isValidTarget(obj) and not Players:GetPlayerFromCharacter(obj) then
                local targetHRP = obj.HumanoidRootPart
                if targetHRP then
                    local distance = (hrp.Position - targetHRP.Position).Magnitude
                    
                    if distance < shortestDistance then
                        local directionToTarget = (targetHRP.Position - hrp.Position).Unit
                        local dotProduct = cameraLookDirection:Dot(directionToTarget)
                        
                        if dotProduct > 0.1 and hasLineOfSight(hrp.Position, targetHRP.Position) then
                            shortestDistance = distance
                            nearest = obj
                        end
                    end
                end
            end
        end
    end
    
    return nearest
end

-- Enhanced prediction for mobile
local function getPredictedPosition(target)
    local targetHRP = target:FindFirstChild("HumanoidRootPart")
    if not targetHRP then return targetHRP.Position end
    
    local velocity = targetHRP.AssemblyLinearVelocity
    local predictedPos = targetHRP.Position + (velocity * Config.PREDICTION_STRENGTH)
    
    return predictedPos
end

-- Update GUI states
local function updateGUIStates()
    aimLockBtn.BackgroundColor3 = currentMode == LockModes.AIM_LOCK and Color3.fromRGB(0, 200, 0) or Color3.fromRGB(50, 50, 50)
    camlockBtn.BackgroundColor3 = currentMode == LockModes.CAM_LOCK and Color3.fromRGB(0, 200, 200) or Color3.fromRGB(50, 50, 50)
    
    if lockTarget then
        local targetName = lockTarget.Name
        local distance = hrp and math.floor((hrp.Position - lockTarget.HumanoidRootPart.Position).Magnitude) or "?"
        statusLabel.Text = string.format("LOCKED: %s (%dm)", targetName, distance)
        statusLabel.TextColor3 = currentMode == LockModes.AIM_LOCK and Color3.fromRGB(255, 200, 0) or Color3.fromRGB(100, 255, 255)
    else
        statusLabel.Text = "READY"
        statusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
    end
end

-- Unlock function
local function unlock()
    lockTarget = nil
    currentMode = LockModes.NONE
    detachBillboard()
    
    -- Disconnect all lock connections
    for _, connection in pairs(connections) do
        if connection then connection:Disconnect() end
    end
    connections = {}
    
    if humanoid then 
        humanoid.AutoRotate = true 
    end
    
    updateGUIStates()
end

-- Lock onto target
local function lockOnto(target, mode)
    if not target then return end
    
    unlock() -- Clear previous lock
    
    lockTarget = target
    currentMode = mode
    attachBillboard(target, mode)
    
    if humanoid and mode == LockModes.AIM_LOCK then
        humanoid.AutoRotate = false
    end
    
    updateGUIStates()
end

-- Mobile-optimized aim lock
local function startAimLock()
    if not lockTarget or not hrp then return end
    
    connections.aimLock = RunService.RenderStepped:Connect(function()
        if lockTarget and hrp and humanoid and humanoid.Health > 0 then
            local targetHRP = lockTarget:FindFirstChild("HumanoidRootPart")
            local targetHum = lockTarget:FindFirstChildWhichIsA("Humanoid")
            
            if targetHRP and targetHum and targetHum.Health > 0 then
                local distance = (hrp.Position - targetHRP.Position).Magnitude
                
                if distance > Config.MAX_DISTANCE then
                    if not Config.STICKY_LOCK then
                        unlock()
                        return
                    end
                end
                
                -- Mobile-optimized smooth rotation
                local predictedPos = getPredictedPosition(lockTarget)
                local lookDirection = (Vector3.new(predictedPos.X, hrp.Position.Y, predictedPos.Z) - hrp.Position).Unit
                local targetCFrame = CFrame.new(hrp.Position, hrp.Position + lookDirection)
                
                hrp.CFrame = hrp.CFrame:Lerp(targetCFrame, Config.AIM_SMOOTHNESS)
                updateGUIStates()
            else
                unlock()
            end
        end
    end)
end

-- Mobile-optimized camlock
local function startCamLock()
    if not lockTarget then return end
    
    connections.camLock = RunService.RenderStepped:Connect(function()
        if lockTarget then
            local targetHRP = lockTarget:FindFirstChild("HumanoidRootPart")
            local targetHum = lockTarget:FindFirstChildWhichIsA("Humanoid")
            
            if targetHRP and targetHum and targetHum.Health > 0 then
                local distance = hrp and (hrp.Position - targetHRP.Position).Magnitude or math.huge
                
                if distance > Config.MAX_DISTANCE then
                    if not Config.STICKY_LOCK then
                        unlock()
                        return
                    end
                end
                
                -- Mobile-optimized camera tracking
                local predictedPos = getPredictedPosition(lockTarget)
                local targetCFrame = CFrame.new(camera.CFrame.Position, predictedPos)
                
                camera.CFrame = camera.CFrame:Lerp(targetCFrame, Config.CAM_SMOOTHNESS)
                updateGUIStates()
            else
                unlock()
            end
        end
    end)
end

-- Touch button connections
aimLockBtn.Activated:Connect(function()
    if currentMode == LockModes.AIM_LOCK then
        unlock()
    else
        local target = getNearestTarget()
        if target then
            lockOnto(target, LockModes.AIM_LOCK)
            startAimLock()
        else
            statusLabel.Text = "NO TARGET FOUND"
            statusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
            wait(2)
            if not lockTarget then
                statusLabel.Text = "READY"
                statusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
            end
        end
    end
end)

camlockBtn.Activated:Connect(function()
    if currentMode == LockModes.CAM_LOCK then
        unlock()
    else
        local target = getNearestTarget()
        if target then
            lockOnto(target, LockModes.CAM_LOCK)
            startCamLock()
        else
            statusLabel.Text = "NO TARGET FOUND"
            statusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
            wait(2)
            if not lockTarget then
                statusLabel.Text = "READY"
                statusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
            end
        end
    end
end)

unlockBtn.Activated:Connect(function()
    unlock()
end)

-- Auto target switching for mobile
spawn(function()
    while true do
        wait(1) -- Longer interval for mobile performance
        if lockTarget and Config.STICKY_LOCK then
            local currentDistance = hrp and (hrp.Position - lockTarget.HumanoidRootPart.Position).Magnitude or math.huge
            local newTarget = getNearestTarget()
            
            if newTarget and newTarget ~= lockTarget then
                local newDistance = hrp and (hrp.Position - newTarget.HumanoidRootPart.Position).Magnitude or math.huge
                
                if newDistance < currentDistance - Config.SWITCH_DISTANCE then
                    lockOnto(newTarget, currentMode)
                    if currentMode == LockModes.AIM_LOCK then
                        startAimLock()
                    elseif currentMode == LockModes.CAM_LOCK then
                        startCamLock()
                    end
                end
            end
        end
    end
end)

-- Initialize
updateGUIStates()
statusLabel.Text = "MOBILE READY ✓"

print("Mobile Lock-On System loaded!")
print("Touch the buttons to use: Aim Lock, Camlock, or Unlock")
