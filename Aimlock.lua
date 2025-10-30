--[[
    Script: Aim-Spy System (v5 - Max Range)
    Purpose: A passive, mobile-first spy tool.
             - NEW: Adds customizable "Max Range" (Studs) filter.
             - NEW: Displays distance in "studs" not "m".
             - No hotkey (toggle only)
             - Target Info tab (Health, Distance, Tool)
             - Threat Assessment
    Library: Rayfield UI (sirius.menu)
]]

--==============================================================================
-- Load Rayfield Library
--==============================================================================
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

--==============================================================================
-- Services & Globals
--==============================================================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local ScreenGui = Instance.new("ScreenGui")

--==============================================================================
-- Configuration
--==============================================================================
local SETTINGS = {
    AimPart = "HumanoidRootPart",
    VisCheck = true,
    Priority = "Crosshair", -- "Crosshair" or "Distance"
    FOV_Size = 250,
    FOV_Color = Color3.fromRGB(255, 255, 255),
    FOV_Visible = true,
    ThreatThreshold = 0.85,
    MaxRange = 200 -- NEW: Default max range in studs
}

-- Global state variables
local SpyEnabled = false
local SpyStatusLabel, TargetHealthLabel, TargetDistanceLabel, TargetToolLabel, ThreatLabel = nil, nil, nil, nil, nil
local FOV_Circle = nil

--==============================================================================
-- Create FOV Circle GUI
--==============================================================================
ScreenGui.Name = "AimSpy_FOV_GUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")

FOV_Circle = Instance.new("ImageLabel")
FOV_Circle.Name = "FOV_Circle"
FOV_Circle.Parent = ScreenGui
FOV_Circle.Image = "rbxassetid://6348420387"
FOV_Circle.ImageColor3 = SETTINGS.FOV_Color
FOV_Circle.ImageTransparency = 0.75
FOV_Circle.BackgroundTransparency = 1
FOV_Circle.AnchorPoint = Vector2.new(0.5, 0.5)
FOV_Circle.Position = UDim2.fromScale(0.5, 0.5)
FOV_Circle.Size = UDim2.fromOffset(SETTINGS.FOV_Size, SETTINGS.FOV_Size)
FOV_Circle.Visible = SETTINGS.FOV_Visible
ScreenGui.Enabled = SETTINGS.FOV_Visible

--==============================================================================
-- Helper Functions (The Core Logic)
--==============================================================================

local function isTeammate(player)
    if not LocalPlayer.Team then return false end
    if not player.Team then return false end
    return player.Team == LocalPlayer.Team
end

local function isAlive(player)
    local char = player.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum and hum.Health > 0 then
            return true
        end
    end
    return false
end

local function getTargetPart(player)
    if player.Character then
        return player.Character:FindFirstChild(SETTINGS.AimPart)
    end
    return nil
end

local function isVisible(targetPart)
    local myChar = LocalPlayer.Character
    if not myChar then return false end
    
    local origin = Camera.CFrame.Position
    local direction = (targetPart.Position - origin).Unit * (SETTINGS.MaxRange + 10)
    
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {myChar}
    
    local result = workspace:Raycast(origin, direction, params)
    
    if result and result.Instance then
        return result.Instance:IsDescendantOf(targetPart.Parent)
    end
    return false
end

--- UPDATED: findBestTarget (now includes Max Range)
local function findBestTarget()
    local bestTarget = nil
    local bestPriority = math.huge
    local crosshairPos = Camera.ViewportSize / 2
    local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    
    if not myRoot then return nil end -- Need our own character to check range

    for _, player in ipairs(Players:GetPlayers())
        -- 1. FILTERING
        if player == LocalPlayer or not isAlive(player) or isTeammate(player) then
            continue
        end
        
        local targetPart = getTargetPart(player)
        if not targetPart then
            continue
        end

        -- 2. NEW: MAX RANGE CHECK
        local dist3D = (targetPart.Position - myRoot.Position).Magnitude
        if dist3D > SETTINGS.MaxRange then
            continue -- Target is too far
        end

        -- 3. FOV & VISIBILITY CHECK
        local screenPos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
        if not onScreen then
            continue
        end
        
        local distFromCrosshair = (Vector2.new(screenPos.X, screenPos.Y) - crosshairPos).Magnitude
        if distFromCrosshair > (SETTINGS.FOV_Size / 2) then
            continue -- Outside of FOV Circle
        end
        
        if SETTINGS.VisCheck and not isVisible(targetPart) then
            continue -- Behind a wall
        end

        -- 4. PRIORITIZATION
        if SETTINGS.Priority == "Crosshair" then
            if distFromCrosshair < bestPriority then
                bestPriority = distFromCrosshair
                bestTarget = player
            end
        elseif SETTINGS.Priority == "Distance" then
            -- We already calculated dist3D
            if dist3D < bestPriority then
                bestPriority = dist3D
                bestTarget = player
            end
        end
    end
    
    return bestTarget -- Returns the *Player* object
end

--==============================================================================
-- Main UI
--==============================================================================

local Window = Rayfield:CreateWindow({
    Name = "Aim-Spy Dashboard",
    LoadingTitle = "Loading System...",
    LoadingSubtitle = "by " .. LocalPlayer.Name,
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "AimAssistConfig",
        FileName = "AimSpyV5_Mobile"
    }
})

local MainTab = Window:CreateTab("Settings", 4483362458)
local InfoTab = Window:CreateTab("Target Info", 3000898399)
local FOVTab = Window:CreateTab("FOV", 5943224891)

-- ===== Settings Tab =====

MainTab:CreateSection("Core")

MainTab:CreateToggle({
    Name = "Enable Aim-Spy",
    CurrentValue = false,
    Flag = "AimSpyToggle",
    Callback = function(Value)
        SpyEnabled = Value
    end
})

-- NEW: Max Range Slider
MainTab:CreateSlider({
    Name = "Max Range (Studs)",
    Range = {50, 1000},
    Increment = 10,
    Suffix = "studs",
    Default = SETTINGS.MaxRange,
    Value = SETTINGS.MaxRange,
    Callback = function(Value)
        SETTINGS.MaxRange = Value
    end
})

MainTab:CreateDropdown({
    Name = "Target Part",
    Options = {"HumanoidRootPart", "Head"},
    Default = SETTINGS.AimPart,
    Callback = function(Value)
        SETTINGS.AimPart = Value
    end
})

MainTab:CreateDropdown({
    Name = "Target Priority",
    Options = {"Crosshair", "Distance"},
    Default = SETTINGS.Priority,
    Callback = function(Value)
        SETTINGS.Priority = Value
    end
})

MainTab:CreateToggle({
    Name = "Visibility Check",
    CurrentValue = SETTINGS.VisCheck,
    Flag = "VisCheckToggle",
    Callback = function(Value)
        SETTINGS.VisCheck = Value
    end
})

-- ===== Target Info Tab =====

InfoTab:CreateSection("Spy Status")
SpyStatusLabel = InfoTab:CreateLabel("Status: IDLE")
ThreatLabel = InfoTab:CreateLabel("Threat: N/A")

InfoTab:CreateSection("Live Data")
TargetHealthLabel = InfoTab:CreateLabel("Health: N/A")
TargetDistanceLabel = InfoTab:CreateLabel("Distance: N/A")
TargetToolLabel = InfoTab:CreateLabel("Tool: N/A")

-- ===== FOV Tab =====

FOVTab:CreateSection("FOV Circle")

FOVTab:CreateToggle({
    Name = "Show FOV Circle",
    CurrentValue = SETTINGS.FOV_Visible,
    Flag = "FOVToggle",
    Callback = function(Value)
        SETTINGS.FOV_Visible = Value
        ScreenGui.Enabled = Value
    end
})

FOVTab:CreateSlider({
    Name = "FOV Circle Size",
    Range = {50, 500},
    Increment = 10,
    Suffix = "px",
    Default = SETTINGS.FOV_Size,
    Value = SETTINGS.FOV_Size,
    Callback = function(Value)
        SETTINGS.FOV_Size = Value
        FOV_Circle.Size = UDim2.fromOffset(Value, Value)
    end
})

FOVTab:CreateColorPicker({
    Name = "FOV Circle Color",
    Default = SETTINGS.FOV_Color,
    Callback = function(Value)
        SETTINGS.FOV_Color = Value
        FOV_Circle.ImageColor3 = Value
    end
})

--==============================================================================
-- Core Loop
--==============================================================================

local function resetLabels()
    SpyStatusLabel:Set("Status: IDLE")
    ThreatLabel:Set("Threat: N/A")
    TargetHealthLabel:Set("Health: N/A")
    TargetDistanceLabel:Set("Distance: N/A")
    TargetToolLabel:Set("Tool: N/A")
end

RunService.RenderStepped:Connect(function()
    if not SpyEnabled or not SpyStatusLabel then
        return
    end

    local TargetPlayer = findBestTarget()
    local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")

    if TargetPlayer and TargetPlayer.Character and myRoot then
        local TargetChar = TargetPlayer.Character
        local TargetPart = TargetChar:FindFirstChild(SETTINGS.AimPart)
        local TargetHum = TargetChar:FindFirstChildOfClass("Humanoid")
        
        if not TargetPart or not TargetHum then
            resetLabels()
            return
        end

        -- Update Status
        SpyStatusLabel:Set("Status: LOCKED (" .. TargetPlayer.Name .. ")")

        -- Update Live Data
        TargetHealthLabel:Set("Health: " .. math.floor(TargetHum.Health) .. " / " .. math.floor(TargetHum.MaxHealth))
        
        -- FIXED: Display in studs
        local dist = math.floor((TargetPart.Position - myRoot.Position).Magnitude)
        TargetDistanceLabel:Set("Distance: " .. dist .. " studs")

        -- Update Tool
        local tool = TargetChar:FindFirstChildOfClass("Tool")
        TargetToolLabel:Set("Tool: " .. (tool and tool.Name or "None"))

        -- Update Threat
        local targetLookVector = TargetPart.CFrame.LookVector
        local toMe = (myRoot.Position - TargetPart.Position).Unit
        local dot = targetLookVector:Dot(toMe)
        
        if dot > SETTINGS.ThreatThreshold then
            ThreatLabel:Set("Threat: !! DANGER !!")
        else
            ThreatLabel:Set("Threat: Low")
        end

    else
        -- No target found
        resetLabels()
    end
end)
