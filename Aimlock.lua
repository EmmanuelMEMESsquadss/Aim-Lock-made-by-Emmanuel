--[[
    Script: Advanced Server Hop v5 (SELF-CONTAINED)
    Library: Venyx UI (Full source code included)
    
    This script includes the entire Venyx library source code
    to prevent errors from game:HttpGet() on mobile executors.
]]

--==============================================================================
-- [START] Venyx UI Library Source Code
--==============================================================================
-- This is the full code for the Venyx UI library.
-- Do not edit this section.

local Venyx = {}
Venyx.__index = Venyx
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local Stats = game:GetService("Stats")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local function new(options)
	local self = setmetatable({}, Venyx)
	self.options = {
		title = options.title or "Venyx",
		toggle = options.toggle,
		key = options.key or Enum.KeyCode.RightShift,
		save = optionsE.save,
		autoSave = optionsE.autoSave,
		blur = options.blur,
		theme = options.theme or {
			Background = Color3.fromRGB(24, 24, 24),
			Glow = Color3.fromRGB(0, 0, 0),
			Accent = Color3.fromRGB(10, 10, 10),
			LightContrast = Color3.fromRGB(20, 20, 20),
			DarkContrast = Color3.fromRGB(14, 14, 14),
			TextColor = Color3.fromRGB(255, 255, 255)
		},
		ad = options.ad or false
	}
	self.pages = {}
	self.selected = nil
	self.dragging = false
	self.oldMousePos = nil
	self.visible = true
	self.elements = {}
	self:construct()
	if self.options.toggle then
		self.background.Visible = false
		self.visible = false
	end
	if self.options.ad then
		self:Notify(self.options.ad.title, self.options.ad.text, self.options.ad.duration, self.options.ad.callback)
	end
	return self
end
local function construct(self)
	self.background = Instance.new("ScreenGui")
	self.background.Name = "Venyx_Background"
	self.background.ZIndexBehavior = Enum.ZIndexBehavior.Global
	self.background.ResetOnSpawn = false
	self.main = Instance.new("Frame")
	self.main.Name = "Main"
	self.main.Parent = self.background
	self.main.AnchorPoint = Vector2.new(0.5, 0.5)
	self.main.Position = UDim2.new(0.5, 0, 0.5, 0)
	self.main.Size = UDim2.new(0, 500, 0, 300)
	self.main.BackgroundColor3 = self.options.theme.Background
	self.main.BorderColor3 = self.options.theme.Glow
	self.main.BorderSizePixel = 2
	self.main.Active = true
	self.main.Draggable = true
	self.sidebar = Instance.new("Frame")
	self.sidebar.Name = "Sidebar"
	self.sidebar.Parent = self.main
	self.sidebar.Size = UDim2.new(0, 100, 1, 0)
	self.sidebar.BackgroundColor3 = self.options.theme.Accent
	self.sidebar.BorderColor3 = self.options.theme.Glow
	self.sidebar.BorderSizePixel = 2
	self.sidebarButtons = Instance.new("ScrollingFrame")
	self.sidebarButtons.Name = "SidebarButtons"
	self.sidebarButtons.Parent = self.sidebar
	self.sidebarButtons.Size = UDim2.new(1, 0, 1, 0)
	self.sidebarButtons.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	self.sidebarButtons.BackgroundTransparency = 1
	self.sidebarButtons.BorderColor3 = Color3.fromRGB(0, 0, 0)
	self.sidebarButtons.BorderSizePixel = 0
	self.sidebarButtons.ScrollingDirection = Enum.ScrollingDirection.Y
	self.sidebarButtons.ScrollBarThickness = 5
	self.sidebarButtons.ScrollBarImageColor3 = self.options.theme.Accent
	self.UILayout = Instance.new("UIListLayout")
	self.UILayout.Parent = self.sidebarButtons
	self.UILayout.SortOrder = Enum.SortOrder.LayoutOrder
	self.UILayout.Padding = UDim.new(0, 5)
	self.container = Instance.new("Frame")
	self.container.Name = "Container"
	self.container.Parent = self.main
	self.container.Position = UDim2.new(0, 100, 0, 0)
	self.container.Size = UDim2.new(1, -100, 1, 0)
	self.container.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	self.container.BackgroundTransparency = 1
	self.container.BorderColor3 = Color3.fromRGB(0, 0, 0)
	self.container.BorderSizePixel = 0
	self.title = Instance.new("TextLabel")
	self.title.Name = "Title"
	self.title.Parent = self.main
	self.title.Size = UDim2.new(1, 0, 0, 20)
	self.title.BackgroundColor3 = self.options.theme.Accent
	self.title.BorderColor3 = self.options.theme.Glow
	self.title.BorderSizePixel = 2
	self.title.Text = self.options.title
	self.title.TextColor3 = self.options.theme.TextColor
	self.title.TextSize = 18
	self.title.Font = Enum.Font.SourceSans
	self.title.TextWrapped = true
	self.title.TextXAlignment = Enum.TextXAlignment.Left
	local textBounds = TweenService:GetTextBoundsAsync(self.options.title, Enum.Font.SourceSans, 18, self.main.AbsoluteSize.X)
	self.title.TextLabel.Size = UDim2.new(0, textBounds.X + 10, 0, 20)
	self.background.Parent = PlayerGui
	if self.options.blur then
		local blur = Instance.new("BlurEffect")
		blur.Name = "Blur"
		blur.Parent = game:GetService("Lighting")
		blur.Size = 24
		blur.Enabled = self.visible
	end
	local function drag(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			self.dragging = true
			self.oldMousePos = Vector2.new(input.Position.X, input.Position.Y)
		end
	end
	local function dragEnd(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			self.dragging = false
			self.oldMousePos = nil
		end
	end
	local function dragMove(input)
		if self.dragging and self.oldMousePos then
			local delta = Vector2.new(input.Position.X, input.Position.Y) - self.oldMousePos
			self.main.Position = UDim2.new(self.main.Position.X.Scale, self.main.Position.X.Offset + delta.X, self.main.Position.Y.Scale, self.main.Position.Y.Offset + delta.Y)
			self.oldMousePos = Vector2.new(input.Position.X, input.Position.Y)
		end
	end
	self.main.InputBegan:Connect(drag)
	self.main.InputEnded:Connect(dragEnd)
	UserInputService.InputChanged:Connect(dragMove)
	if self.options.toggle then
		UserInputService.InputBegan:Connect(function(input, gameProcessed)
			if not gameProcessed and input.KeyCode == self.options.key then
				self:toggle()
			end
		end)
	end
	self:Notify("Venyx", "Loaded", 3)
end
local function addPage(self, options)
	local page = {}
	page.options = {
		title = options.title or "Page",
		icon = options.icon or ""
	}
	page.sections = {}
	page.button = Instance.new("ImageButton")
	page.button.Name = page.options.title
	page.button.Parent = self.sidebarButtons
	page.button.Size = UDim2.new(1, 0, 0, 40)
	page.button.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	page.button.BackgroundTransparency = 1
	page.button.Image = "rbxassetid://" .. page.options.icon
	page.button.ImageColor3 = self.options.theme.TextColor
	page.button.ScaleType = Enum.ScaleType.Fit
	page.button.LayoutOrder = #self.pages + 1
	page.frame = Instance.new("ScrollingFrame")
	page.frame.Name = page.options.title
	page.frame.Parent = self.container
	page.frame.Size = UDim2.new(1, 0, 1, 0)
	page.frame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	page.frame.BackgroundTransparency = 1
	page.frame.BorderColor3 = Color3.fromRGB(0, 0, 0)
	page.frame.BorderSizePixel = 0
	page.frame.Visible = false
	page.frame.ScrollingDirection = Enum.ScrollingDirection.Y
	page.frame.ScrollBarThickness = 5
	page.frame.ScrollBarImageColor3 = self.options.theme.Accent
	page.UILayout = Instance.new("UIListLayout")
	page.UILayout.Parent = page.frame
	page.UILayout.SortOrder = Enum.SortOrder.LayoutOrder
	page.UILayout.Padding = UDim.new(0, 5)
	page.button.MouseButton1Click:Connect(function()
		self:select(page)
	end)
	table.insert(self.pages, page)
	if #self.pages == 1 then
		self:select(page)
	end
	local function addSection(options)
		local section = {}
		section.options = {
			title = options.title or "Section"
		}
		section.elements = {}
		section.frame = Instance.new("Frame")
		section.frame.Name = section.options.title
		section.frame.Parent = page.frame
		section.frame.Size = UDim2.new(1, -10, 0, 100)
		section.frame.BackgroundColor3 = self.options.theme.Accent
		section.frame.BorderColor3 = self.options.theme.Glow
		section.frame.BorderSizePixel = 2
		section.frame.ClipsDescendants = true
		section.title = Instance.new("TextLabel")
		section.title.Name = "Title"
		section.title.Parent = section.frame
		section.title.Size = UDim2.new(1, 0, 0, 20)
		section.title.BackgroundColor3 = self.options.theme.LightContrast
		section.title.BorderColor3 = self.options.theme.Glow
		section.title.BorderSizePixel = 2
		section.title.Text = section.options.title
		section.title.TextColor3 = self.options.theme.TextColor
		section.title.TextSize = 16
		section.title.Font = Enum.Font.SourceSans
		section.title.TextWrapped = true
		section.container = Instance.new("Frame")
		section.container.Name = "Container"
		section.container.Parent = section.frame
		section.container.Position = UDim2.new(0, 0, 0, 20)
		section.container.Size = UDim2.new(1, 0, 1, -20)
		section.container.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		section.container.BackgroundTransparency = 1
		section.container.BorderColor3 = Color3.fromRGB(0, 0, 0)
		section.container.BorderSizePixel = 0
		section.UILayout = Instance.new("UIListLayout")
		section.UILayout.Parent = section.container
		section.UILayout.SortOrder = Enum.SortOrder.LayoutOrder
		section.UILayout.Padding = UDim.new(0, 5)
		table.insert(page.sections, section)
		local function updateSize()
			local contentSize = section.UILayout.AbsoluteContentSize
			section.frame.Size = UDim2.new(1, -10, 0, 20 + contentSize.Y + 5)
		end
		section.UILayout.Changed:Connect(updateSize)
		updateSize()
		local function addButton(options)
			local button = {}
			button.options = {
				title = options.title or "Button",
				callback = options.callback or function() end
			}
			button.button = Instance.new("TextButton")
			button.button.Name = button.options.title
			button.button.Parent = section.container
			button.button.Size = UDim2.new(1, 0, 0, 30)
			button.button.BackgroundColor3 = self.options.theme.LightContrast
			button.button.BorderColor3 = self.options.theme.Glow
			button.button.BorderSizePixel = 2
			button.button.Text = button.options.title
			button.button.TextColor3 = self.options.theme.TextColor
			button.button.TextSize = 14
			button.button.Font = Enum.Font.SourceSans
			button.button.MouseButton1Click:Connect(button.options.callback)
			table.insert(section.elements, button)
			updateSize()
			return button
		end
		local function addToggle(options)
			local toggle = {}
			toggle.options = {
				title = options.title or "Toggle",
				default = options.default or false,
				callback = options.callback or function() end
			}
			toggle.value = toggle.options.default
			toggle.button = Instance.new("TextButton")
			toggle.button.Name = toggle.options.title
			toggle.button.Parent = section.container
			toggle.button.Size = UDim2.new(1, 0, 0, 30)
			toggle.button.BackgroundColor3 = self.options.theme.LightContrast
			toggle.button.BorderColor3 = self.options.theme.Glow
			toggle.button.BorderSizePixel = 2
			toggle.button.Text = toggle.options.title
			toggle.button.TextColor3 = self.options.theme.TextColor
			toggle.button.TextSize = 14
			toggle.button.Font = Enum.Font.SourceSans
			toggle.indicator = Instance.new("Frame")
			toggle.indicator.Name = "Indicator"
			toggle.indicator.Parent = toggle.button
			toggle.indicator.AnchorPoint = Vector2.new(1, 0.5)
			toggle.indicator.Position = UDim2.new(1, -5, 0.5, 0)
			toggle.indicator.Size = UDim2.new(0, 20, 0, 20)
			toggle.indicator.BackgroundColor3 = toggle.value and self.options.theme.Glow or self.options.theme.DarkContrast
			toggle.indicator.BorderColor3 = self.options.theme.Glow
			toggle.indicator.BorderSizePixel = 2
			toggle.button.MouseButton1Click:Connect(function()
				toggle.value = not toggle.value
				toggle.indicator.BackgroundColor3 = toggle.value and self.options.theme.Glow or self.options.theme.DarkContrast
				toggle.options.callback(toggle.value)
			end)
			table.insert(section.elements, toggle)
			updateSize()
			function toggle:setTitle(title)
				toggle.button.Text = title
			end
			return toggle
		end
		local function addTextbox(options)
			local textbox = {}
			textbox.options = {
				title = options.title or "Textbox",
				placeholder = options.placeholder or "",
				default = options.default or "",
				callback = options.callback or function() end
			}
			textbox.value = textbox.options.default
			textbox.button = Instance.new("Frame")
			textbox.button.Name = textbox.options.title
			textbox.button.Parent = section.container
			textbox.button.Size = UDim2.new(1, 0, 0, 30)
			textbox.button.BackgroundColor3 = self.options.theme.LightContrast
			textbox.button.BorderColor3 = self.options.theme.Glow
			textbox.button.BorderSizePixel = 2
			textbox.title = Instance.new("TextLabel")
			textbox.title.Name = "Title"
			textbox.title.Parent = textbox.button
			textbox.title.Size = UDim2.new(0.5, 0, 1, 0)
			textbox.title.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			textbox.title.BackgroundTransparency = 1
			textbox.title.Text = textbox.options.title
			textbox.title.TextColor3 = self.options.theme.TextColor
			textbox.title.TextSize = 14
			textbox.title.Font = Enum.Font.SourceSans
			textbox.title.TextXAlignment = Enum.TextXAlignment.Left
			textbox.textbox = Instance.new("TextBox")
			textbox.textbox.Name = "Textbox"
			textbox.textbox.Parent = textbox.button
			textbox.textbox.AnchorPoint = Vector2.new(1, 0.5)
			textbox.textbox.Position = UDim2.new(1, -5, 0.5, 0)
			textbox.textbox.Size = UDim2.new(0.5, -5, 0, 20)
			textbox.textbox.BackgroundColor3 = self.options.theme.DarkContrast
			textbox.textbox.BorderColor3 = self.options.theme.Glow
			textbox.textbox.BorderSizePixel = 2
			textbox.textbox.Text = textbox.options.default
			textbox.textbox.PlaceholderText = textbox.options.placeholder
			textbox.textbox.TextColor3 = self.options.theme.TextColor
			textbox.textbox.TextSize = 14
			textbox.textbox.Font = Enum.Font.SourceSans
			textbox.textbox.ClearTextOnFocus = false
			textbox.textbox.FocusLost:Connect(function(enterPressed)
				textbox.value = textbox.textbox.Text
				textbox.options.callback(textbox.value, enterPressed)
			end)
			table.insert(section.elements, textbox)
			updateSize()
			return textbox
		end
		local function addSlider(options)
			local slider = {}
			slider.options = {
				title = options.title or "Slider",
				min = options.min or 0,
				max = options.max or 100,
				default = options.default or 0,
				callback = options.callback or function() end
			}
			slider.value = slider.options.default
			slider.button = Instance.new("Frame")
			slider.button.Name = slider.options.title
			slider.button.Parent = section.container
			slider.button.Size = UDim2.new(1, 0, 0, 30)
			slider.button.BackgroundColor3 = self.options.theme.LightContrast
			slider.button.BorderColor3 = self.options.theme.Glow
			slider.button.BorderSizePixel = 2
			slider.title = Instance.new("TextLabel")
			slider.title.Name = "Title"
			slider.title.Parent = slider.button
			slider.title.Size = UDim2.new(1, 0, 1, 0)
			slider.title.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			slider.title.BackgroundTransparency = 1
			slider.title.Text = slider.options.title .. " (" .. slider.value .. ")"
			slider.title.TextColor3 = self.options.theme.TextColor
			slider.title.TextSize = 14
			slider.title.Font = Enum.Font.SourceSans
			slider.slider = Instance.new("Frame")
			slider.slider.Name = "Slider"
			slider.slider.Parent = slider.button
			slider.slider.AnchorPoint = Vector2.new(0.5, 1)
			slider.slider.Position = UDim2.new(0.5, 0, 1, -5)
			slider.slider.Size = UDim2.new(1, -10, 0, 10)
			slider.slider.BackgroundColor3 = self.options.theme.DarkContrast
			slider.slider.BorderColor3 = self.options.theme.Glow
			slider.slider.BorderSizePixel = 2
			slider.fill = Instance.new("Frame")
			slider.fill.Name = "Fill"
			slider.fill.Parent = slider.slider
			slider.fill.Size = UDim2.new((slider.value - slider.options.min) / (slider.options.max - slider.options.min), 0, 1, 0)
			slider.fill.BackgroundColor3 = self.options.theme.Glow
			slider.fill.BorderColor3 = self.options.theme.Glow
			slider.fill.BorderSizePixel = 2
			local function updateSlider(input)
				local pos = input.Position.X - slider.slider.AbsolutePosition.X
				local percent = math.clamp(pos / slider.slider.AbsoluteSize.X, 0, 1)
				slider.value = math.floor(slider.options.min + (slider.options.max - slider.options.min) * percent + 0.5)
				slider.fill.Size = UDim2.new(percent, 0, 1, 0)
				slider.title.Text = slider.options.title .. " (" .. slider.value .. ")"
				slider.options.callback(slider.value)
			end
			slider.slider.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 then
					updateSlider(input)
					slider.dragging = true
				end
			end)
			slider.slider.InputEnded:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 then
					slider.dragging = false
				end
			end)
			slider.slider.InputChanged:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseMovement and slider.dragging then
					updateSlider(input)
				end
			end)
			table.insert(section.elements, slider)
			updateSize()
			return slider
		end
		return {
			addSection = addSection,
			addButton = addButton,
			addToggle = addToggle,
			addTextbox = addTextbox,
			addSlider = addSlider
		}
	end
	return {
		addSection = addSection
	}
end
local function select(self, page)
	if self.selected then
		self.selected.frame.Visible = false
		self.selected.button.ImageColor3 = self.options.theme.TextColor
	end
	self.selected = page
	self.selected.frame.Visible = true
	self.selected.button.ImageColor3 = self.options.theme.Glow
end
local function Notify(self, title, text, duration, callback)
	local notif = Instance.new("Frame")
	notif.Name = "Notification"
	notif.Parent = self.background
	notif.AnchorPoint = Vector2.new(0.5, 0)
	notif.Position = UDim2.new(0.5, 0, 0, 10)
	notif.Size = UDim2.new(0, 200, 0, 50)
	notif.BackgroundColor3 = self.options.theme.Background
	notif.BorderColor3 = self.options.theme.Glow
	notif.BorderSizePixel = 2
	local notifTitle = Instance.new("TextLabel")
	notifTitle.Name = "Title"
	notifTitle.Parent = notif
	notifTitle.Size = UDim2.new(1, 0, 0, 20)
	notifTitle.BackgroundColor3 = self.options.theme.Accent
	notifTitle.BorderColor3 = self.options.theme.Glow
	notifTitle.BorderSizePixel = 2
	notifTitle.Text = title
	notifTitle.TextColor3 = self.options.theme.TextColor
	notifTitle.TextSize = 16
	notifTitle.Font = Enum.Font.SourceSans
	notifTitle.TextWrapped = true
	local notifText = Instance.new("TextLabel")
	notifText.Name = "Text"
	notifText.Parent = notif
	notifText.Position = UDim2.new(0, 0, 0, 20)
	notifText.Size = UDim2.new(1, 0, 1, -20)
	notifText.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	notifText.BackgroundTransparency = 1
	notifText.Text = text
	notifText.TextColor3 = self.options.theme.TextColor
	notifText.TextSize = 14
	notifText.Font = Enum.Font.SourceSans
	notifText.TextWrapped = true
	if callback then
		local button = Instance.new("TextButton")
		button.Name = "Button"
		button.Parent = notif
		button.AnchorPoint = Vector2.new(0.5, 1)
		button.Position = UDim2.new(0.5, 0, 1, -5)
		button.Size = UDim2.new(1, -10, 0, 20)
		button.BackgroundColor3 = self.options.theme.LightContrast
		button.BorderColor3 = self.options.theme.Glow
		button.BorderSizePixel = 2
		button.Text = "Callback"
		button.TextColor3 = self.options.theme.TextColor
		button.TextSize = 14
		button.Font = Enum.Font.SourceSans
		button.MouseButton1Click:Connect(function()
			callback()
			notif:Destroy()
		end)
		notif.Size = UDim2.new(0, 200, 0, 75)
		notifText.Size = UDim2.new(1, 0, 1, -45)
	end
	local function tween()
		local info = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		local goal = {
			Position = UDim2.new(0.5, 0, 0, -60)
		}
		local tween = TweenService:Create(notif, info, goal)
		tween:Play()
		tween.Completed:Wait()
		notif:Destroy()
	end
	task.wait(duration)
	tween()
end
local function toggle(self)
	self.visible = not self.visible
	self.background.Visible = self.visible
	if self.options.blur then
		self.background:FindFirstChild("Blur").Enabled = self.visible
	end
end
Venyx.new = new
Venyx.construct = construct
Venyx.addPage = addPage
Venyx.select = select
Venyx.Notify = Notify
Venyx.toggle = toggle

--==============================================================================
-- [END] Venyx UI Library Source Code
--==============================================================================


--==============================================================================
-- [START] Your Server Hop Script
--==============================================================================
-- All the code below this line is your actual script.

local UI = Venyx.new({
    title = "Advanced Server Hop v5 (Internal)",
    toggle = true,
    key = Enum.KeyCode.RightShift -- (This keybind may not work on mobile, but the UI should still appear)
})

-- Define Globals
_G.LastServerJobId = _G.LastServerJobId or nil
_G.JobIdInput = ""
_G.PingThreshold = 120

-- Helper Functions
local function SaveCurrentJobId()
    _G.LastServerJobId = CurrentJobId
end

local function Teleport(hopFunction, ...)
    SaveCurrentJobId()
    pcall(hopFunction, ...)
end

local function Notify(Title, Text)
    UI:Notify(Title, Text, 5)
end

-- Main Tab (Hopping)
local HopPage = UI:addPage({
    title = "Server Hop",
    icon = 4483362458
})

local QuickHopSection = HopPage:addSection({
    title = "Quick Hops"
})

QuickHopSection:addButton({
    title = "Hop to Random Server",
    callback = function()
        Notify("Hopping", "Finding a random server...")
        Teleport(TeleportService.Teleport, TeleportService, CurrentPlaceId, LocalPlayer)
    end
})

QuickHopSection:addButton({
    title = "Hop to Smallest Server",
    callback = function()
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

local RejoinSection = HopPage:addSection({
    title = "Rejoin"
})

RejoinSection:addButton({
    title = "Rejoin Current Server",
    callback = function()
        Notify("Rejoining", "Rejoining this server...")
        pcall(TeleportService.TeleportToPlaceInstance, TeleportService, CurrentPlaceId, CurrentJobId, LocalPlayer)
    end
})

RejoinSection:addButton({
    title = "Rejoin Previous Server",
    callback = function()
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

local SpecificHopSection = HopPage:addSection({
    title = "Specific Hop"
})

SpecificHopSection:addTextbox({
    title = "Job ID",
    placeholder = "Enter Job ID...",
    callback = function(value, focusLost)
        _G.JobIdInput = value
    end
})

SpecificHopSection:addButton({
    title = "Hop to Job ID",
    callback = function()
        if _G.JobIdInput and _G.JobIdInput ~= "" then
            Notify("Specific Hop", "Joining Job ID...")
            Teleport(TeleportService.TeleportToPlaceInstance, TeleportService, CurrentPlaceId, _G.JobIdInput, LocalPlayer)
        else
            Notify("Error", "Please enter a Job ID.")
        end
    end
})

-- Performance Tab
local PerformancePage = UI:addPage({
    title = "Performance",
    icon = 3000898399
})

local StatsSection = PerformancePage:addSection({
    title = "Live Stats"
})

local PingLabel = StatsSection:addToggle({
    title = "Current Ping: Fetching...",
    callback = function() end
})

local FPSLabel = StatsSection:addToggle({
    title = "Current FPS: Fetching...",
    callback = function() end
})

local LocationSection = PerformancePage:addSection({
    title = "Server Location"
})

local RegionLabel = LocationSection:addToggle({
    title = "Server Region: (Click 'Fetch')",
    callback = function() end
})

LocationSection:addButton({
    title = "Fetch Server Location",
    callback = function()
        RegionLabel:setTitle("Server Region: Fetching...")
        local success, response = pcall(HttpService.GetAsync, HttpService, "https://ipinfo.io/json")
        if success then
            local data = HttpService:JSONDecode(response)
            if data and data.region and data.country then
                local locText = "Region: " .. data.region .. ", " .. data.country
                RegionLabel:setTitle(locText)
                Notify("Location Found", "Server is in " .. data.city .. ", " .. data.country)
            else
                RegionLabel:setTitle("Server Region: Error decoding.")
            end
        else
            RegionLabel:setTitle("Server Region: API failed.")
            Notify("Error", "Could not fetch server location.")
        end
    end
})

local AutoHopSection = PerformancePage:addSection({
    title = "Auto-Hop (Based on Ping)"
})

AutoHopSection:addSlider({
    title = "Max Ping Threshold (ms)",
    min = 50,
    max = 300,
    default = 120,
    callback = function(value)
        _G.PingThreshold = value
    end
})

AutoHopSection:addToggle({
    title = "Auto-Hop when Ping > Threshold",
    callback = function(State)
        _G.AutoHopping = State
        if State then
            Notify("Auto-Hop Enabled", "Will hop if ping > " .. _G.PingThreshold .. " ms.")
            task.spawn(function()
                while _G.AutoHopping do
                    local currentPing = math.floor(Stats.Network.Ping:GetValue() * 1000)
                    if currentPing > _G.PingThreshold then
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

-- Stats Update Loop
task.spawn(function()
    while task.wait(1) do
        pcall(function()
            local currentPing = math.floor(Stats.Network.Ping:GetValue() * 1000)
            PingLabel:setTitle("Current Ping: " .. tostring(currentPing) .. " ms")
            
            local currentFPS = math.floor(Stats.Performance.FPS:GetValue())
            FPSLabel:setTitle("Current FPS: " .. tostring(currentFPS))
        end)
    end
end)

--==============================================================================
-- [END] Your Server Hop Script
--==============================================================================
