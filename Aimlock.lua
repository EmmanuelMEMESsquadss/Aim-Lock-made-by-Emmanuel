--[[
    Script: Advanced Server Hop Utility v4 (Mobile Compatible)
    Library: Orion UI (Designed for mobile executors like Arceus X)
    Purpose: A mobile-friendly version of the server hop utility.
]]

--==============================================================================
-- Services & Globals
--==============================================================================
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local Stats = game:GetService("Stats")

local LocalPlayer = Players.LocalPlayer
local CurrentPlaceId = game.PlaceId
local CurrentJobId = game.JobId

-- Global variable to store the last server we were in
_G.LastServerJobId = _G.LastServerJobId or nil

--==============================================================================
-- Helper Functions
--==============================================================================
local function SaveCurrentJobId()
    _G.LastServerJobId = CurrentJobId
end

local function Teleport(hopFunction, ...)
    SaveCurrentJobId()
    pcall(hopFunction, ...)
end

local function Notify(Title, Text)
    -- Orion has a built-in notification system
    OrionLib:MakeNotification({
        Name = Title,
        Content = Text,
        Image = "rbxassetid://4483362458", -- Default icon
        Time = 5
    })
end

--==============================================================================
-- Load Orion Library & Create Window
--==============================================================================

local OrionLib = loadstring(game:HttpGet(('https://raw.githubusercontent.com/shlexware/Orion/main/source')))()
local Window = OrionLib:MakeWindow({
    Name = "Advanced Server Hop",
    HidePremium = false,
    SaveConfig = true,
    ConfigFolder = "OrionHopConfig",
    IntroText = "Mobile Server Hop",
    IntroIcon = "rbxassetid://4483362458"
})

--==============================================================================
-- Main Tab (Hopping)
--==============================================================================

local HopTab = Window:MakeTab({
    Name = "Server Hop",
    Icon = "rbxassetid://4483362458",
    PremiumOnly = false
})

HopTab:AddSection("Quick Hops")

HopTab:AddButton({
    Name = "Hop to Random Server",
    Callback = function()
        Notify("Hopping", "Finding a random server...")
        Teleport(TeleportService.Teleport, TeleportService, CurrentPlaceId, LocalPlayer)
    end
})

HopTab:AddButton({
    Name = "Hop to Smallest Server",
    Callback = function()
        Notify("Hopping", "Finding smallest server...")
        
        Teleport(function()
            local url = "https://games.roblox.com/v1/games/" .. CurrentPlaceId .. "/servers/Public?sortOrder=Asc&limit=10"
            local success, response = pcall(HttpService.GetAsync, HttpService, url)
            
            if success then
                local serverData = HttpService:JSONDecode(response)
                if serverData and serverData.data and #serverData.data > 0 then
                    local smallestServerJobId = serverData.data[1].id
                    TeleportService:TeleportToPlaceInstance(CurrentPlaceId, smallestServerJobId, LocalPlayer)
                else
                    Notify("Error", "Could not find server. Hopping random.")
                    TeleportService:Teleport(CurrentPlaceId, LocalPlayer)
                end
            else
                Notify("HTTP Error", "Hopping to random server.")
                TeleportService:Teleport(CurrentPlaceId, LocalPlayer)
            end
        end)
    end
})

HopTab:AddSection("Rejoin")

HopTab:AddButton({
    Name = "Rejoin Current Server",
    Callback = function()
        Notify("Rejoining", "Rejoining this server...")
        pcall(TeleportService.TeleportToPlaceInstance, TeleportService, CurrentPlaceId, CurrentJobId, LocalPlayer)
    end
})

HopTab:AddButton({
    Name = "Rejoin Previous Server",
    Callback = function()
        if _G.LastServerJobId then
            Notify("Rejoining", "Joining previous server...")
            local tempJobId = CurrentJobId
            pcall(TeleportService.TeleportToPlaceInstance, TeleportService, CurrentPlaceId, _G.LastServerJobId, LocalPlayer)
            _G.LastServerJobId = tempJobId
        else
            Notify("Error", "No previous server saved.")
        end
    end
})

HopTab:AddSection("Specific Hop")

local JobIdInput -- Declare it here

HopTab:AddTextbox({
    Name = "Job ID",
    Text = "Enter Job ID...",
    Default = "",
    Callback = function(Text)
        -- In Orion, the textbox callback *is* the input.
        -- We'll store it in our variable.
        JobIdInput = Text
    end
})

HopTab:AddButton({
    Name = "Hop to Job ID",
    Callback = function()
        if JobIdInput and JobIdInput ~= "" then
            Notify("Specific Hop", "Joining Job ID...")
            Teleport(TeleportService.TeleportToPlaceInstance, TeleportService, CurrentPlaceId, JobIdInput, LocalPlayer)
        else
            Notify("Error", "Please enter a Job ID.")
        end
    end
})

--==============================================================================
-- Performance Tab
--==============================================================================

local PerformanceTab = Window:MakeTab({
    Name = "Performance",
    Icon = "rbxassetid://3000898399",
    PremiumOnly = false
})

PerformanceTab:AddSection("Live Stats")

-- Orion doesn't have a simple "Label" that we can update.
-- We will use a Toggle to display the info, which is a common mobile UI workaround.
local PingLabel = PerformanceTab:AddToggle({
    Name = "Current Ping: Fetching...",
    Default = false,
    Callback = function() end
})
-- Disable the toggle from being clicked
PingLabel.Toggle.Interactable = false 

local FPSLabel = PerformanceTab:AddToggle({
    Name = "Current FPS: Fetching...",
    Default = false,
    Callback = function() end
})
FPSLabel.Toggle.Interactable = false

PerformanceTab:AddSection("Server Location (Bloxstrap Feature)")

local RegionLabel = PerformanceTab:AddToggle({
    Name = "Server Region: (Click 'Fetch')",
    Default = false,
    Callback = function() end
})
RegionLabel.Toggle.Interactable = false

PerformanceTab:AddButton({
    Name = "Fetch Server Location",
    Callback = function()
        RegionLabel.Name = "Server Region: Fetching..."
        RegionLabel:Update() -- Update the label text
        
        local success, response = pcall(HttpService.GetAsync, HttpService, "https://ipinfo.io/json")
        
        if success then
            local data = HttpService:JSONDecode(response)
            if data and data.region and data.country then
                local locText = "Region: " .. data.region .. ", " .. data.country
                RegionLabel.Name = locText
                RegionLabel:Update()
                Notify("Location Found", "Server is in " .. data.city .. ", " .. data.country)
            else
                RegionLabel.Name = "Server Region: Error decoding."
                RegionLabel:Update()
            end
        else
            RegionLabel.Name = "Server Region: API failed."
            RegionLabel:Update()
            Notify("Error", "Could not fetch server location.")
        end
    end
})

PerformanceTab:AddSection("Auto-Hop (Based on Ping)")

local PingThreshold = 120 -- Default value

PerformanceTab:AddSlider({
    Name = "Max Ping Threshold (ms)",
    Min = 50,
    Max = 300,
    Default = 120,
    Color = Color3.fromRGB(0, 255, 255),
    Increment = 10,
    ValueName = "ms",
    Callback = function(Value)
        PingThreshold = Value
    end
})

PerformanceTab:AddToggle({
    Name = "Auto-Hop when Ping > Threshold",
    Default = false,
    Callback = function(State)
        _G.AutoHopping = State
        
        if State then
            Notify("Auto-Hop Enabled", "Will hop if ping > " .. PingThreshold .. " ms.")
            task.spawn(function()
                while _G.AutoHopping do
                    local currentPing = math.floor(Stats.Network.Ping:GetValue() * 1000)
                    if currentPing > PingThreshold then
                        _G.AutoHopping = false
                        Notify("Bad Ping!", "Hopping... (" .. currentPing .. " ms)")
                        Teleport(TeleportService.Teleport, TeleportService, CurrentPlaceId, LocalPlayer)
                        break
                    end
                    task.wait(5)
                end
            end)
        else
            Notify("Auto-Hop Disabled", "Manual hopping only.")
        end
    end
})

--==============================================================================
-- Stats Update Loop
--==============================================================================

task.spawn(function()
    while task.wait(1) do
        pcall(function()
            -- Get Ping
            local currentPing = math.floor(Stats.Network.Ping:GetValue() * 1000)
            PingLabel.Name = "Current Ping: " .. tostring(currentPing) .. " ms"
            PingLabel:Update()
            
            -- Get FPS
            local currentFPS = math.floor(Stats.Performance.FPS:GetValue())
            FPSLabel.Name = "Current FPS: " .. tostring(currentFPS)
            FPSLabel:Update()
        end)
    end
end)
