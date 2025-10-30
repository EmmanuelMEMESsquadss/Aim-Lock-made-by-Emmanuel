--[[
    Script: Aim-Spy System (v3 - Pro Features)
    Purpose: A passive, read-only aim-assist logic system.
             - Adds Visibility Check (Raycast)
             - Adds Target Priority (Crosshair, Distance)
             - Adds a client-side FOV Circle
    Library: Rayfield UI
]]

--==============================================================================
-- Load Rayfield Library
--==============================================================================
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

--==============================================================================
-- Services & Globals
--==============================================================================
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local ScreenGui = Instance.new("ScreenGui")

--==============================================================================
-- Configuration
--==============================================================================
local SETTINGS = {
    SpyKey = Enum.KeyCode.F,
    AimPart = "HumanoidRootPart",
    VisCheck = true,
    Priority = "Crosshair", -- "Crosshair" or "Distance"
    FOV_Size = 250, -- in pixels
    FOV_Color = Color3.fromRGB(255, 255, 255),
    FOV_Visible = true
}

-- Global state variables
local SpyEnabled = false
local IsSpying = false
local SpyStatusLabel = nil
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
FOV_Circle.Image = "rbxassetid://6348420387" -- A basic circle image
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

--- NEW: Visibility Check
local function isVisible(targetPart)
    local myChar = LocalPlayer.Character
    if not myChar then return false end
    
    local origin = Camera.CFrame.Position
    local direction = (targetPart.Position - origin).Unit * 1000 -- 1000 studs range
    
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {myChar} -- Ignore our own character
    
    local result = workspace:Raycast(origin, direction, params)
    
    if result and result.Instance then
        -- It's visible if the ray hit the target's character
        return result.Instance:IsDescendantOf(targetPart.Parent)
    end
    return false
end


--- UPDATED: findBestTarget (now includes all logic)
local function findBestTarget()
    local bestTarget = nil
    local bestPriority = math.huge
    local crosshairPos = Camera.ViewportSize / 2
    local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")

    for _, player in ipairs(Players:GetPlayers()) do
        -- 1. FILTERING
        if player == LocalPlayer or not isAlive(player) or isTeammate(player) then
            continue
        end
        
        local targetPart = getTargetPart(player)
        if not targetPart then
            continue
        end

        -- 2. FOV & VISIBILITY CHECK
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

        -- 3. PRIORITIZATION
        if SETTINGS.Priority == "Crosshair" then
            if distFromCrosshair < bestPriority then
                bestPriority = distFromCrosshair
                bestTarget = player
            end
        elseif SETTINGS.Priority == "Distance" then
            if myRoot then
                local dist3D = (targetPart.Position - myRoot.Position).Magnitude
                if dist3D < bestPriority then
                    bestPriority = dist3D
                    bestTarget = player
                end
            end
        end
    end
    
    return bestTarget -- Returns the *Player* object
end

--==============================================================================
-- Main UI
--==============================================================================

local Window = Rayfield:CreateWindow({
    Name = "Aim-Spy System",
    LoadingTitle = "Loading System...",
    LoadingSubtitle = "by " .. LocalPlayer.Name,
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "AimAssistConfig",
        FileName = "AimSpyV3"
    }
})

local MainTab = Window:CreateTab("Main", 4483362458)

MainTab:CreateToggle({
    Name = "Enable Aim-Spy",
    CurrentValue = false,
    Flag = "AimSpyToggle",
    Callback = function(Value)
        SpyEnabled = Value
        if not Value then IsSpying = false end
    end
})

MainTab:CreateLabel("Hold [" .. SETTINGS.SpyKey.Name .. "] to spy.")

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

MainTab:CreateSection("FOV Circle")

SpyStatusLabel = MainTab:CreateLabel("Status: IDLE (Hold " .. SETTINGS.SpyKey.Name .. ")")

MainTab:CreateToggle({
    Name = "Show FOV Circle",
    CurrentValue = SETTINGS.FOV_Visible,
    Flag = "FOVToggle",
    Callback = function(Value)
        SETTINGS.FOV_Visible = Value
        ScreenGui.Enabled = Value
    end
})

MainTab:CreateSlider({
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

MainTab:CreateColorPicker({
    Name = "FOV Circle Color",
    Default = SETTINGS.FOV_Color,
    Callback = function(Value)
        SETTINGS.FOV_Color = Value
        FOV_Circle.ImageColor3 = Value
    end
})

--==============================================================================
-- Core Loop & Input Handlers
--==============================================================================

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == SETTINGS.SpyKey then
        IsSpying = true
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode == SETTINGS.SpyKey then
        IsSpying = false
        if SpyStatusLabel then
            SpyStatusLabel:Set("Status: IDLE (Hold " .. SETTINGS.SpyKey.Name .. ")")
        end
    end
end)

-- The main "spy" loop
RunService.RenderStepped:Connect(function()
    if IsSpying and SpyEnabled and SpyStatusLabel then
        local TargetPlayer = findBestTarget() -- This returns the *Player* object

        if TargetPlayer then
            SpyStatusLabel:Set("Status: LOCKED (" .. TargetPlayer.Name .. ")")
        else
            SpyStatusLabel:Set("Status: CLEAR")
        end
    end
end)
