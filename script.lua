local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer

-- == CONFIGURATION ==
local config = {
	autoStick = false,
	enabled = false,
	distance = 15,       -- Range: 5 to 20 studs
	speed = 0.3,         -- Range: 0.1 to 1.0
	height = 0,          -- Height offset above head
	smoothness = 0.5,    -- Range: 0.1 to 1.0
	uiVisible = true,
	targetChar = nil,
	isAttached = false,
	stuckChar = nil,
	followSpeed = 11.7
}

-- Saved Configurations Store
local savedConfigs = {}

-- == ANIME PINK PALETTE ==
local PALETTE = {
	Background = Color3.fromRGB(30, 20, 32),
	AccentStart = Color3.fromRGB(255, 120, 180),
	AccentEnd = Color3.fromRGB(255, 180, 220),
	Text = Color3.fromRGB(255, 235, 245),
	SubText = Color3.fromRGB(230, 190, 215),
	Container = Color3.fromRGB(45, 30, 48),
	OnColor = Color3.fromRGB(255, 105, 180),
	OffColor = Color3.fromRGB(80, 50, 75),
	ButtonGlow = Color3.fromRGB(255, 140, 195)
}

-- == UI CREATION ==
local Gui = Instance.new("ScreenGui")
Gui.Name = "RatolUIAnime"
Gui.ResetOnSpawn = false
Gui.Parent = player:FindFirstChild("PlayerGui") or game:GetService("CoreGui")

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 330, 0, 620)
MainFrame.Position = UDim2.new(0.5, -165, 0.5, -310)
MainFrame.BackgroundColor3 = PALETTE.Background
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.ClipsDescendants = true
MainFrame.Parent = Gui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 18)
MainCorner.Parent = MainFrame

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = PALETTE.AccentStart
MainStroke.Thickness = 2
MainStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
MainStroke.Parent = MainFrame

local BackgroundGradient = Instance.new("UIGradient")
BackgroundGradient.Color = ColorSequence.new{
	ColorSequenceKeypoint.new(0, Color3.fromRGB(40, 25, 42)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(20, 12, 22))
}
BackgroundGradient.Rotation = 60
BackgroundGradient.Parent = MainFrame

-- Header
local HeaderFrame = Instance.new("Frame")
HeaderFrame.Size = UDim2.new(1, 0, 0, 55)
HeaderFrame.BackgroundTransparency = 1
HeaderFrame.Parent = MainFrame

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 1, 0)
Title.BackgroundTransparency = 1
Title.Text = "🌸 RATOL UI 🌸"
Title.TextColor3 = PALETTE.Text
Title.TextSize = 22
Title.Font = Enum.Font.FredokaOne
Title.Parent = HeaderFrame

local TitleGradient = Instance.new("UIGradient")
TitleGradient.Color = ColorSequence.new{
	ColorSequenceKeypoint.new(0, PALETTE.AccentStart),
	ColorSequenceKeypoint.new(1, PALETTE.AccentEnd)
}
TitleGradient.Parent = Title

-- Scroll Container
local ScrollContainer = Instance.new("ScrollingFrame")
ScrollContainer.Size = UDim2.new(1, -24, 1, -65)
ScrollContainer.Position = UDim2.new(0, 12, 0, 60)
ScrollContainer.BackgroundTransparency = 1
ScrollContainer.BorderSizePixel = 0
ScrollContainer.ScrollBarThickness = 3
ScrollContainer.ScrollBarImageColor3 = PALETTE.AccentStart
ScrollContainer.CanvasSize = UDim2.new(0, 0, 0, 620)
ScrollContainer.Parent = MainFrame

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.Padding = UDim.new(0, 10)
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Parent = ScrollContainer

-- References for updating UI dynamically on config load
local uiElements = {
	toggles = {},
	sliders = {}
}

-- UI Component Helpers
local function createToggle(keyName, text, defaultValue, callback)
	local Frame = Instance.new("Frame")
	Frame.Size = UDim2.new(1, -6, 0, 40)
	Frame.BackgroundColor3 = PALETTE.Container
	Frame.Parent = ScrollContainer
	
	Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 10)
	
	local Label = Instance.new("TextLabel")
	Label.Size = UDim2.new(0.65, -10, 1, 0)
	Label.Position = UDim2.new(0, 12, 0, 0)
	Label.BackgroundTransparency = 1
	Label.Text = text
	Label.TextColor3 = PALETTE.Text
	Label.TextSize = 13
	Label.Font = Enum.Font.FredokaOne
	Label.TextXAlignment = Enum.TextXAlignment.Left
	Label.Parent = Frame
	
	local Btn = Instance.new("TextButton")
	Btn.Size = UDim2.new(0, 60, 0, 26)
	Btn.Position = UDim2.new(1, -68, 0.5, -13)
	Btn.BackgroundColor3 = defaultValue and PALETTE.OnColor or PALETTE.OffColor
	Btn.Text = defaultValue and "ON" or "OFF"
	Btn.TextColor3 = Color3.fromRGB(255, 255, 255)
	Btn.Font = Enum.Font.FredokaOne
	Btn.TextSize = 12
	Btn.Parent = Frame
	
	Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 8)
	
	local function updateToggleState(state)
		Btn.Text = state and "ON" or "OFF"
		TweenService:Create(Btn, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			BackgroundColor3 = state and PALETTE.OnColor or PALETTE.OffColor
		}):Play()
		callback(state)
	end
	
	Btn.MouseButton1Click:Connect(function()
		local newState = not (Btn.Text == "ON")
		updateToggleState(newState)
	end)
	
	uiElements.toggles[keyName] = updateToggleState
	return Btn
end

local function createSlider(keyName, text, min, max, default, callback)
	local Frame = Instance.new("Frame")
	Frame.Size = UDim2.new(1, -6, 0, 52)
	Frame.BackgroundColor3 = PALETTE.Container
	Frame.Parent = ScrollContainer
	
	Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 10)
	
	local Label = Instance.new("TextLabel")
	Label.Size = UDim2.new(1, -24, 0, 20)
	Label.Position = UDim2.new(0, 12, 0, 6)
	Label.BackgroundTransparency = 1
	Label.Text = text .. ": " .. tostring(default)
	Label.TextColor3 = PALETTE.SubText
	Label.TextSize = 12
	Label.Font = Enum.Font.FredokaOne
	Label.TextXAlignment = Enum.TextXAlignment.Left
	Label.Parent = Frame
	
	local SliderBack = Instance.new("Frame")
	SliderBack.Size = UDim2.new(1, -24, 0, 8)
	SliderBack.Position = UDim2.new(0, 12, 0, 32)
	SliderBack.BackgroundColor3 = Color3.fromRGB(20, 12, 22)
	SliderBack.Parent = Frame
	Instance.new("UICorner", SliderBack).CornerRadius = UDim.new(1, 0)
	
	local Fill = Instance.new("Frame")
	local fillPct = (default - min) / (max - min)
	Fill.Size = UDim2.new(fillPct, 0, 1, 0)
	Fill.BackgroundColor3 = PALETTE.AccentStart
	Fill.Parent = SliderBack
	Instance.new("UICorner", Fill).CornerRadius = UDim.new(1, 0)
	
	local dragging = false
	
	local function updateValue(val)
		val = math.clamp(val, min, max)
		local pct = (val - min) / (max - min)
		Fill.Size = UDim2.new(pct, 0, 1, 0)
		Label.Text = text .. ": " .. tostring(val)
		callback(val)
	end
	
	SliderBack.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
		end
	end)
	
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)
	
	RunService.RenderStepped:Connect(function()
		if dragging then
			local mousePos = UserInputService:GetMouseLocation().X
			local framePos = SliderBack.AbsolutePosition.X
			local frameSize = SliderBack.AbsoluteSize.X
			local pct = math.clamp((mousePos - framePos) / frameSize, 0, 1)
			local val = math.floor((min + (max - min) * pct) * 100) / 100
			updateValue(val)
		end
	end)
	
	uiElements.sliders[keyName] = updateValue
end

-- Physics Controls
local alignPosition, alignOrientation, attachment0, attachment1

local function cleanupPhysics()
	config.isAttached = false
	config.targetChar = nil
	if alignPosition then alignPosition:Destroy() alignPosition = nil end
	if alignOrientation then alignOrientation:Destroy() alignOrientation = nil end
	if attachment0 then attachment0:Destroy() attachment0 = nil end
	if attachment1 then attachment1:Destroy() attachment1 = nil end
end

-- Toggles Creation
createToggle("autoStick", "Auto Stick", config.autoStick, function(state)
	config.autoStick = state
	if not state then
		config.stuckChar = nil
	end
end)

local function toggleHeadPull(state)
	if state == nil then
		config.enabled = not config.enabled
	else
		config.enabled = state
	end
	
	if uiElements.toggles["enabled"] then
		uiElements.toggles["enabled"](config.enabled)
	end
	
	if not config.enabled then
		cleanupPhysics()
		config.stuckChar = nil
	end
end

createToggle("enabled", "Head Pull Enabled", config.enabled, function(state)
	toggleHeadPull(state)
end)

createSlider("distance", "Pull Distance", 5, 20, config.distance, function(val) config.distance = val end)
createSlider("speed", "Pull Speed", 0.1, 1.0, config.speed, function(val) config.speed = val end)
createSlider("height", "Pull Height Offset", 0, 10, config.height, function(val) config.height = val end)
createSlider("smoothness", "Smoothness", 0.1, 1.0, config.smoothness, function(val) config.smoothness = val end)

-- == CONFIG MANAGEMENT SECTION WITH LIST ==
local ConfigSection = Instance.new("Frame")
ConfigSection.Size = UDim2.new(1, -6, 0, 210)
ConfigSection.BackgroundColor3 = PALETTE.Container
ConfigSection.Parent = ScrollContainer
Instance.new("UICorner", ConfigSection).CornerRadius = UDim.new(0, 10)

local ConfigTitle = Instance.new("TextLabel")
ConfigTitle.Size = UDim2.new(1, -20, 0, 20)
ConfigTitle.Position = UDim2.new(0, 10, 0, 6)
ConfigTitle.BackgroundTransparency = 1
ConfigTitle.Text = "Configuration Settings"
ConfigTitle.TextColor3 = PALETTE.Text
ConfigTitle.TextSize = 13
ConfigTitle.Font = Enum.Font.FredokaOne
ConfigTitle.TextXAlignment = Enum.TextXAlignment.Left
ConfigTitle.Parent = ConfigSection

local NameInput = Instance.new("TextBox")
NameInput.Size = UDim2.new(0.68, 0, 0, 28)
NameInput.Position = UDim2.new(0, 10, 0, 30)
NameInput.BackgroundColor3 = Color3.fromRGB(20, 12, 22)
NameInput.Text = ""
NameInput.PlaceholderText = "Config name..."
NameInput.PlaceholderColor3 = Color3.fromRGB(150, 120, 140)
NameInput.TextColor3 = PALETTE.Text
NameInput.Font = Enum.Font.FredokaOne
NameInput.TextSize = 12
NameInput.ClearTextOnFocus = false
NameInput.Parent = ConfigSection
Instance.new("UICorner", NameInput).CornerRadius = UDim.new(0, 6)

local SaveBtn = Instance.new("TextButton")
SaveBtn.Size = UDim2.new(0.25, 0, 0, 28)
SaveBtn.Position = UDim2.new(0.72, 0, 0, 30)
SaveBtn.BackgroundColor3 = PALETTE.OnColor
SaveBtn.Text = "Save"
SaveBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
SaveBtn.Font = Enum.Font.FredokaOne
SaveBtn.TextSize = 12
SaveBtn.Parent = ConfigSection
Instance.new("UICorner", SaveBtn).CornerRadius = UDim.new(0, 6)

-- Config List Frame
local ConfigListFrame = Instance.new("ScrollingFrame")
ConfigListFrame.Size = UDim2.new(1, -20, 0, 138)
ConfigListFrame.Position = UDim2.new(0, 10, 0, 64)
ConfigListFrame.BackgroundColor3 = Color3.fromRGB(20, 12, 22)
ConfigListFrame.BorderSizePixel = 0
ConfigListFrame.ScrollBarThickness = 3
ConfigListFrame.ScrollBarImageColor3 = PALETTE.AccentStart
ConfigListFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
ConfigListFrame.Parent = ConfigSection
Instance.new("UICorner", ConfigListFrame).CornerRadius = UDim.new(0, 6)

local ConfigListLayout = Instance.new("UIListLayout")
ConfigListLayout.Padding = UDim.new(0, 4)
ConfigListLayout.SortOrder = Enum.SortOrder.LayoutOrder
ConfigListLayout.Parent = ConfigListFrame

-- Function to load a saved configuration
local function loadConfiguration(cfgName)
	local targetCfg = savedConfigs[cfgName]
	if targetCfg then
		uiElements.toggles["autoStick"](targetCfg.autoStick)
		uiElements.toggles["enabled"](targetCfg.enabled)
		uiElements.sliders["distance"](targetCfg.distance)
		uiElements.sliders["speed"](targetCfg.speed)
		uiElements.sliders["height"](targetCfg.height)
		uiElements.sliders["smoothness"](targetCfg.smoothness)
	end
end

-- Refresh Config List UI
local function refreshConfigList()
	for _, child in pairs(ConfigListFrame:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
	
	local itemCount = 0
	for cfgName, data in pairs(savedConfigs) do
		itemCount = itemCount + 1
		
		local ItemFrame = Instance.new("Frame")
		ItemFrame.Size = UDim2.new(1, -6, 0, 30)
		ItemFrame.BackgroundColor3 = PALETTE.Container
		ItemFrame.Parent = ConfigListFrame
		Instance.new("UICorner", ItemFrame).CornerRadius = UDim.new(0, 6)
		
		local ConfigBtn = Instance.new("TextButton")
		ConfigBtn.Size = UDim2.new(1, -30, 1, 0)
		ConfigBtn.Position = UDim2.new(0, 6, 0, 0)
		ConfigBtn.BackgroundTransparency = 1
		ConfigBtn.Text = "📌 " .. cfgName
		ConfigBtn.TextColor3 = PALETTE.Text
		ConfigBtn.TextSize = 11
		ConfigBtn.Font = Enum.Font.FredokaOne
		ConfigBtn.TextXAlignment = Enum.TextXAlignment.Left
		ConfigBtn.Parent = ItemFrame
		
		ConfigBtn.MouseButton1Click:Connect(function()
			loadConfiguration(cfgName)
			NameInput.Text = cfgName
			
			TweenService:Create(ItemFrame, TweenInfo.new(0.15), {BackgroundColor3 = PALETTE.OnColor}):Play()
			task.wait(0.2)
			TweenService:Create(ItemFrame, TweenInfo.new(0.15), {BackgroundColor3 = PALETTE.Container}):Play()
		end)
		
		local DelBtn = Instance.new("TextButton")
		DelBtn.Size = UDim2.new(0, 24, 0, 24)
		DelBtn.Position = UDim2.new(1, -26, 0.5, -12)
		DelBtn.BackgroundColor3 = PALETTE.OffColor
		DelBtn.Text = "✕"
		DelBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
		DelBtn.Font = Enum.Font.FredokaOne
		DelBtn.TextSize = 11
		DelBtn.Parent = ItemFrame
		Instance.new("UICorner", DelBtn).CornerRadius = UDim.new(0, 6)
		
		DelBtn.MouseButton1Click:Connect(function()
			savedConfigs[cfgName] = nil
			refreshConfigList()
		end)
	end
	
	ConfigListFrame.CanvasSize = UDim2.new(0, 0, 0, itemCount * 34)
end

-- Save Logic
SaveBtn.MouseButton1Click:Connect(function()
	local cfgName = NameInput.Text
	if cfgName == "" or cfgName:match("^%s*$") then
		cfgName = "Default"
		NameInput.Text = "Default"
	end
	
	savedConfigs[cfgName] = {
		autoStick = config.autoStick,
		enabled = config.enabled,
		distance = config.distance,
		speed = config.speed,
		height = config.height,
		smoothness = config.smoothness
	}
	
	refreshConfigList()
	
	local origText = SaveBtn.Text
	SaveBtn.Text = "✓"
	TweenService:Create(SaveBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(80, 220, 130)}):Play()
	task.wait(0.8)
	SaveBtn.Text = origText
	TweenService:Create(SaveBtn, TweenInfo.new(0.2), {BackgroundColor3 = PALETTE.OnColor}):Play()
end)

-- Helpers
function getNearestPlayer()
	local char = player.Character
	if not char or not char:FindFirstChild("HumanoidRootPart") then return nil end
	
	local root = char.HumanoidRootPart
	local nearest, minDist = nil, config.distance
	
	for _, p in pairs(Players:GetPlayers()) do
		if p ~= player and p.Character and p.Character:FindFirstChild("HumanoidRootPart") and p.Character:FindFirstChild("Head") then
			local dist = (p.Character.HumanoidRootPart.Position - root.Position).Magnitude
			if dist < minDist then
				minDist = dist
				nearest = p
			end
		end
	end
	return nearest
end

local function applyPhysicsPull(targetChar)
	cleanupPhysics()
	
	local myChar = player.Character
	local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
	local targetHead = targetChar and targetChar:FindFirstChild("Head")
	
	if not myRoot or not targetHead then return end
	
	local myHipHeight = myChar:FindFirstChildOfClass("Humanoid") and myChar.Humanoid.HipHeight or 2
	local exactLandingOffset = (targetHead.Size.Y / 2) + myHipHeight + config.height
	
	attachment0 = Instance.new("Attachment", myRoot)
	attachment1 = Instance.new("Attachment", targetHead)
	attachment1.Position = Vector3.new(0, exactLandingOffset, 0)
	
	alignPosition = Instance.new("AlignPosition")
	alignPosition.Attachment0 = attachment0
	alignPosition.Attachment1 = attachment1
	alignPosition.MaxForce = 100000
	alignPosition.MaxVelocity = config.speed * 60
	alignPosition.Responsiveness = config.smoothness * 100
	alignPosition.Parent = myRoot
	
	alignOrientation = Instance.new("AlignOrientation")
	alignOrientation.Attachment0 = attachment0
	alignOrientation.Attachment1 = attachment1
	alignOrientation.MaxTorque = 100000
	alignOrientation.Responsiveness = config.smoothness * 100
	alignOrientation.Parent = myRoot
	
	config.targetChar = targetChar
	config.isAttached = true
end

local function triggerJumpPull()
	if not config.enabled then return end
	local nearest = getNearestPlayer()
	if nearest and nearest.Character then
		applyPhysicsPull(nearest.Character)
	end
end

-- Bind Jump
local function bindCharacter(char)
	local humanoid = char:WaitForChild("Humanoid", 5)
	if humanoid then
		humanoid.Jumping:Connect(function()
			triggerJumpPull()
		end)
	end
end

if player.Character then bindCharacter(player.Character) end
player.CharacterAdded:Connect(bindCharacter)

-- Main Loop
RunService.Heartbeat:Connect(function(dt)
	local myChar = player.Character
	local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
	
	-- Active Pull Physics
	if config.enabled and config.isAttached and config.targetChar then
		local targetHead = config.targetChar:FindFirstChild("Head")
		
		if alignPosition and attachment1 and myChar and targetHead then
			local myHipHeight = myChar:FindFirstChildOfClass("Humanoid") and myChar.Humanoid.HipHeight or 2
			local exactLandingOffset = (targetHead.Size.Y / 2) + myHipHeight + config.height
			
			alignPosition.MaxVelocity = config.speed * 60
			alignPosition.Responsiveness = config.smoothness * 100
			attachment1.Position = Vector3.new(0, exactLandingOffset, 0)
			
			-- Arrival Trigger for Auto-Stick
			if (myRoot.Position - attachment1.WorldPosition).Magnitude < 1.0 then
				if config.autoStick then
					config.stuckChar = config.targetChar
				end
				cleanupPhysics()
			end
		end
		
		-- Target Check
		if not config.targetChar:FindFirstChild("Humanoid") or config.targetChar.Humanoid.Health <= 0 then
			cleanupPhysics()
			config.stuckChar = nil
		end
	end

	-- Auto Stick Snap-Back Mechanics (ONLY ACTIVE IF HEAD PULL IS ENABLED AND USER HAS INTENTIONALLY JUMPED)
	if config.enabled and config.autoStick and config.stuckChar and not config.isAttached and myRoot then
		local targetHead = config.stuckChar:FindFirstChild("Head")
		
		if targetHead and config.stuckChar:FindFirstChild("Humanoid") and config.stuckChar.Humanoid.Health > 0 then
			local myHipHeight = myChar:FindFirstChildOfClass("Humanoid") and myChar.Humanoid.HipHeight or 2
			local exactLandingOffset = (targetHead.Size.Y / 2) + myHipHeight + config.height
			
			local headTargetPos = (targetHead.CFrame * CFrame.new(0, exactLandingOffset, 0)).Position
			local horizontalDist = Vector2.new(myRoot.Position.X - headTargetPos.X, myRoot.Position.Z - headTargetPos.Z).Magnitude
			local verticalDist = math.abs(myRoot.Position.Y - headTargetPos.Y)
			
			-- Pull back when stepping too far off
			if horizontalDist > 1.8 or verticalDist > 2.0 then
				local targetCF = CFrame.new(headTargetPos) * (myRoot.CFrame - myRoot.Position)
				local alpha = 1 - math.exp(-config.followSpeed * dt)
				
				myRoot.AssemblyLinearVelocity = Vector3.zero
				myRoot.CFrame = myRoot.CFrame:Lerp(targetCF, alpha)
			end
		else
			config.stuckChar = nil
		end
	end
end)

-- Menu Toggle Animation (Z Key)
local isAnimating = false
local function toggleMenuAnimation()
	if isAnimating then return end
	isAnimating = true
	
	config.uiVisible = not config.uiVisible
	
	if config.uiVisible then
		MainFrame.Visible = true
		MainFrame.Size = UDim2.new(0, 330, 0, 0)
		MainFrame.Position = UDim2.new(0.5, -165, 0.5, 0)
		
		local tween = TweenService:Create(MainFrame, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Size = UDim2.new(0, 330, 0, 620),
			Position = UDim2.new(0.5, -165, 0.5, -310)
		})
		tween:Play()
		tween.Completed:Connect(function() isAnimating = false end)
	else
		local tween = TweenService:Create(MainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			Size = UDim2.new(0, 330, 0, 0),
			Position = UDim2.new(0.5, -165, 0.5, 0)
		})
		tween:Play()
		tween.Completed:Connect(function()
			MainFrame.Visible = false
			isAnimating = false
		end)
	end
end

-- Keybind Inputs
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	
	if input.KeyCode == Enum.KeyCode.Z then
		toggleMenuAnimation()
	end
	
	if input.KeyCode == Enum.KeyCode.R or input.KeyCode == Enum.KeyCode.ButtonR1 then
		toggleHeadPull()
	end
end)
