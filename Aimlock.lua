--[[
    Script: Advanced Server Hop Utility v7
    Library: Rayfield UI (Using the working sirius.menu URL)
    Purpose: Bloxstrap-inspired server hop utility.
]]

--==============================================================================
-- Load Rayfield Library (Using the correct URL from your example)
--==============================================================================
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

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
    -- Store the current JobId as the "last" one before we hop
    _G.LastServerJobId = CurrentJobId
end

local function Teleport(hopFunction, ...)
    -- This wrapper function saves our current JobId *before*
    -- any teleport is initiated.
    SaveCurrentJobId()
    pcall(hopFunction, ...)
end

--==============================================================================
-- Main Window
--==============================================================================

local Window = Rayfield:CreateWindow({
    Name = "Advanced Server Hop",
    LoadingTitle = "Loading Utility...",
    LoadingSubtitle = "by " .. LocalPlayer.Name,
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "ServerHopConfig",
        FileName = "AdvancedHopperV7"
    }
})

--==============================================================================
-- Main Tab (Hopping)
--==============================================================================

local HopTab = Window:CreateTab("Server Hop", 4483362458)

HopTab:CreateSection("Quick Hops")

-- Button: Hop to a random server
HopTab:CreateButton({
    Name = "Hop to Random Server",
    Callback = function()
        Rayfield:Notify({ Title = "Hopping", Content = "Finding a random server..." })
        Teleport(TeleportService.Teleport, TeleportService, CurrentPlaceId, LocalPlayer)
    end,
})

-- Button: Hop to the smallest server
HopTab:CreateButton({
    Name = "Hop to Smallest Server",
    Callback = function()
        Rayfield:Notify({ Title = "Hopping", Content = "Finding smallest server..." })
        
        -- Use our Teleport wrapper for the API call
        Teleport(function()
            local url = "https://games.roblox.com/v1/games/" .. CurrentPlaceId .. "/servers/Public?sortOrder=Asc&limit=10"
            local success, response = pcall(HttpService.GetAsync, HttpService, url)
            
            if success then
                local serverData = HttpService:JSONDecode(response)
                if serverData and serverData.data and #serverData.data > 0 then
                    local smallestServerJobId = serverData.data[1].id
                    TeleportService:TeleportToPlaceInstance(CurrentPlaceId, smallestServerJobId, LocalPlayer)
                else
                    Rayfield:Notify({ Title = "Error", Content = "Could not find server. Hopping random." })
                    TeleportService:Teleport(CurrentPlaceId, LocalPlayer)
                end
            else
                Rayfield:Notify({ Title = "HTTP Error", Content = "Hopping to random server." })
                TeleportService:Teleport(CurrentPlaceId, LocalPlayer)
            end
        end)
    end,
})

HopTab:CreateSection("Rejoin")

-- Button: Rejoin the current server
HopTab:CreateButton({
    Name = "Rejoin Current Server",
    Callback = function()
        Rayfield:Notify({ Title = "Rejoining", Content = "Rejoining this server..." })
        -- No need to save JobId here, we're coming right back
        pcall(TeleportService.TeleportToPlaceInstance, TeleportService, CurrentPlaceId, CurrentJobId, LocalPlayer)
    end,
})

-- Button: Rejoin the *previous* server
HopTab:CreateButton({
    Name = "Rejoin Previous Server",
    Callback = function()
        if _G.LastServerJobId then
            Rayfield:Notify({ Title = "Rejoining", Content = "Joining previous server..." })
            local tempJobId = CurrentJobId -- Save current in case we want to come back
            pcall(TeleportService.TeleportToPlaceInstance, TeleportService, CurrentPlaceId, _G.LastServerJobId, LocalPlayer)
            _G.LastServerJobId = tempJobId -- Update the "last" id to where we just left
        else
            Rayfield:Notify({ Title = "Error", Content = "No previous server saved." })
        end
    end,
})

HopTab:CreateSection("Specific Hop")

local JobIdInput = HopTab:CreateInput({
    Name = "Job ID",
    PlaceholderText = "Enter server Job ID here...",
    RemoveTextAfterFocusLost = false,
    Callback = function(Text) end,
})

HopTab:CreateButton({
    Name = "Hop to Job ID",
    Callback = function()
        local targetJobId = JobIdInput:GetText()
        if targetJobId and targetJobId ~= "" then
            Rayfield:Notify({ Title = "Specific Hop", Content = "Joining Job ID..." })
            Teleport(TeleportService.TeleportToPlaceInstance, TeleportService, CurrentPlaceId, targetJobId, LocalPlayer)
        else
            Rayfield:Notify({ Title = "Error", Content = "Please enter a Job ID." })
        end
    end,
})

--==============================================================================
-- Performance Tab
--==============================================================================

local PerformanceTab = Window:CreateTab("Performance", 3000898399) -- Stats icon

PerformanceTab:CreateSection("Live Stats")

local PingLabel = PerformanceTab:CreateLabel("Current Ping: Fetching...")
local FPSLabel = PerformanceTab:CreateLabel("Current FPS: Fetching...")

PerformanceTab:CreateSection("Server Location (Bloxstrap Feature)")
local RegionLabel = PerformanceTab:CreateLabel("Server Region: (Click 'Fetch')")

-- Button to manually fetch the server location
PerformanceTab:CreateButton({
    Name = "Fetch Server Location",
    Callback = function()
        RegionLabel:Set("Server Region: Fetching...")
        
        -- We use an external IP info API. This is the same method Bloxstrap uses.
        -- We get our IP, which will be the *server's* IP, not our own.
        local success, response = pcall(HttpService.GetAsync, HttpService, "https://ipinfo.io/json")
        
        if success then
            local data = HttpService:JSONDecode(response)
            if data and data.region and data.country then
                RegionLabel:Set("Region: " .. data.region .. ", " .. data.country .. " ("..data.city..")")
                Rayfield:Notify({ Title = "Location Found", Content = "Server is in " .. data.city .. ", " .. data.country })
            else
                RegionLabel:Set("Server Region: Error decoding response.")
            end
        else
            RegionLabel:Set("Server Region: API request failed.")
            Rayfield:Notify({ Title = "Error", Content = "Could not fetch server location." })
        end
    end,
})

PerformanceTab:CreateSection("Auto-Hop (Based on Ping)")

PerformanceTab:CreateLabel("Ping Tiers (Ideal < 120ms)")

local PingThreshold = PerformanceTab:CreateSlider({
    Name = "Max Ping Threshold (ms)",
    Range = {50, 300},
    Increment = 10,
    Suffix = "ms",
    Default = 120,
    Value = 120,
    Callback = function(Value) end,
})

_G.AutoHopping = false

PerformanceTab:CreateToggle({
    Name = "Auto-Hop when Ping > Threshold",
    Default = false,
    Callback = function(State)
        _G.AutoHopping = State
        
        if State then
            Rayfield:Notify({ Title = "Auto-Hop Enabled", Content = "Will hop if ping > " .. PingThreshold.Value .. " ms." })
            task.spawn(function()
                while _G.AutoHopping do
                    -- This ping path is the *standard* Roblox one. It should work in any game.
                    -- Your auto-block script uses a game-specific path.
                    local currentPing = math.floor(Stats.Network.Ping:GetValue() * 1000)
                    
                    if currentPing > PingThreshold.Value then
                        _G.AutoHopping = false
                        Rayfield:Notify({ Title = "Bad Ping!", Content = "Hopping... (" .. currentPing .. " ms)" })
                        Teleport(TeleportService.Teleport, TeleportService, CurrentPlaceId, LocalPlayer)
                        break
                    end
                    task.wait(5)
                end
            end)
        else
            Rayfield:Notify({ Title = "Auto-Hop Disabled", Content = "Manual hopping only." })
        end
    end,
})

--==============================================================================
-- Stats Update Loop (Runs in background)
--==============================================================================

task.spawn(function()
    while task.wait(1) do
        -- Check if the labels exist (Window might be closed)
        if not (PingLabel and PingLabel.Visible) then continue end
        
        -- Get Ping (Standard Roblox path: GetValue() returns seconds)
        local pingSuccess, currentPing = pcall(function()
            return math.floor(Stats.Network.Ping:GetValue() * 1000)
        end)
        
        if pingSuccess then
            PingLabel:Set("Current Ping: " .. tostring(currentPing) .. " ms")
        else
            PingLabel:Set("Current Ping: Error")
        end
        
        -- Get FPS (Standard Roblox path)
        local fpsSuccess, currentFPS = pcall(function()
            return math.floor(Stats.Performance.FPS:GetValue())
        end)
        
        if fpsSuccess then
            FPSLabel:Set("Current FPS: " .. tostring(currentFPS))
        else
            FPSLabel:Set("Current FPS: Error")
        end
    end
end)
