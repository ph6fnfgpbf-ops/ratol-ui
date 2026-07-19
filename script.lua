local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local root = character:WaitForChild("HumanoidRootPart")

player.CharacterAdded:Connect(function(char)
	character = char
	humanoid = char:WaitForChild("Humanoid")
	root = char:WaitForChild("HumanoidRootPart")
	originalHandSizes = {}
	originalHandMaterials = {}
	originalHandTransparencies = {}
	originalHandCanCollides = {}
	originalHandColors = {}
	otherPlayerHitboxes = {}
end)

-- SIMPLE STATE SYSTEM
local Features = {}

function Features:new()
	local self = setmetatable({}, self)
	self.states = {}
	self.callbacks = {}
	return self
end

function Features:register(name)
	self.states[name] = false
	self.callbacks[name] = {}
end

function Features:set(name, value)
	self.states[name] = value
	for _, cb in ipairs(self.callbacks[name] or {}) do
		pcall(cb, value)
	end
end

function Features:get(name)
	return self.states[name] or false
end

function Features:toggle(name)
	self:set(name, not self:get(name))
end

function Features:on(name, callback)
	if not self.callbacks[name] then
		self.callbacks[name] = {}
	end
	table.insert(self.callbacks[name], callback)
end

Features.__index = Features

local state = Features:new()
state:register("sticky")
state:register("boost")
state:register("loop")
state:register("gravity")
state:register("hitbox")
state:register("gloves")
state:register("invisibleGloves")

-- VALUES
local pullStrength = 2.5
local stickiness = 3
local detectionRange = 25
local boostPower = 70
local loopSpeed = 21.4
local gravityValue = 196
local hitboxSize = 2.3
local hitboxTransparency = 1
local gloveSize = 6
local gloveTransparency = 0.35
local otherPlayerHitboxes = {}
local originalHandSizes = {}
local originalHandMaterials = {}
local originalHandTransparencies = {}
local originalHandCanCollides = {}
local originalHandColors = {}

-- HEAD BOOST SETTINGS
local BOOST_COOLDOWN = 3
local onCooldown = false
local cdRemaining = 0

local keybinds = {
	sticky = Enum.KeyCode.G,
	boost = Enum.KeyCode.E,
	loop = Enum.KeyCode.C,
	gravity = Enum.KeyCode.J,
	hitbox = Enum.KeyCode.H,
	gloves = Enum.KeyCode.X
}

-- GUI SETUP (unchanged - same as before)
local PlayerGui = player:WaitForChild("PlayerGui")
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "RatolGui"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = PlayerGui

local Main = Instance.new("Frame")
Main.Size = UDim2.new(0, 380, 0, 620)
Main.Position = UDim2.new(0.5, -190, 0.5, -310)
Main.BackgroundColor3 = Color3.fromRGB(12, 12, 18)
Main.Active = true
Main.Draggable = true
Main.Parent = ScreenGui
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 16)

local Title = Instance.new("TextLabel", Main)
Title.Size = UDim2.new(1, 0, 0, 50)
Title.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
Title.Text = "FLAME"
Title.TextColor3 = Color3.new(1, 0.6, 0.1)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 24
Title.TextXAlignment = Enum.TextXAlignment.Center
Instance.new("UICorner", Title).CornerRadius = UDim.new(0, 16)

local HideButton = Instance.new("TextButton", Main)
HideButton.Size = UDim2.new(0, 40, 0, 32)
HideButton.Position = UDim2.new(1, -48, 0, 9)
HideButton.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
HideButton.Text = "-"
HideButton.TextColor3 = Color3.new(1,1,1)
HideButton.Font = Enum.Font.GothamBold
HideButton.TextSize = 20
Instance.new("UICorner", HideButton).CornerRadius = UDim.new(0, 8)

local OpenButton = Instance.new("TextButton", PlayerGui)
OpenButton.Size = UDim2.new(0, 80, 0, 80)
OpenButton.Position = UDim2.new(1, -100, 1, -100)
OpenButton.BackgroundColor3 = Color3.fromRGB(25, 20, 35)
OpenButton.Text = "F"
OpenButton.TextColor3 = Color3.fromRGB(255, 100, 20)
OpenButton.Font = Enum.Font.GothamBold
OpenButton.TextSize = 32
OpenButton.Visible = false
Instance.new("UICorner", OpenButton).CornerRadius = UDim.new(0, 20)

HideButton.MouseButton1Click:Connect(function() 
	Main.Visible = false 
	OpenButton.Visible = true 
end)

OpenButton.MouseButton1Click:Connect(function() 
	Main.Visible = true 
	OpenButton.Visible = false 
end)

local Scroll = Instance.new("ScrollingFrame", Main)
Scroll.Size = UDim2.new(1, -20, 1, -70)
Scroll.Position = UDim2.new(0, 10, 0, 55)
Scroll.BackgroundTransparency = 1
Scroll.ScrollBarThickness = 6
Scroll.ScrollBarImageColor3 = Color3.fromRGB(255, 90, 30)
Scroll.CanvasSize = UDim2.new(0, 0, 0, 0)

-- TOGGLE & VALUE ADJUSTER FUNCTIONS (same as last version)
local function makeToggleSlider(parent, ypos, title, featureName)
	-- ... (identical to previous version - omitted for brevity)
	local container = Instance.new("Frame", parent)
	container.Size = UDim2.new(1, -10, 0, 50)
	container.Position = UDim2.new(0, 5, 0, ypos)
	container.BackgroundColor3 = Color3.fromRGB(25, 28, 35)
	Instance.new("UICorner", container).CornerRadius = UDim.new(0, 10)

	local lbl = Instance.new("TextLabel", container)
	lbl.Size = UDim2.new(0.6, 0, 0, 20)
	lbl.Position = UDim2.new(0.05, 0, 0, 5)
	lbl.Text = title
	lbl.TextColor3 = Color3.new(1, 1, 1)
	lbl.Font = Enum.Font.GothamBold
	lbl.TextSize = 14
	lbl.BackgroundTransparency = 1

	local statusLabel = Instance.new("TextLabel", container)
	statusLabel.Size = UDim2.new(0.3, 0, 0, 20)
	statusLabel.Position = UDim2.new(0.65, 0, 0, 5)
	statusLabel.Text = "OFF"
	statusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
	statusLabel.Font = Enum.Font.GothamBold
	statusLabel.TextSize = 12
	statusLabel.BackgroundTransparency = 1

	local track = Instance.new("Frame", container)
	track.Size = UDim2.new(0.9, 0, 0, 24)
	track.Position = UDim2.new(0.05, 0, 0, 23)
	track.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
	Instance.new("UICorner", track).CornerRadius = UDim.new(0, 8)

	local slider = Instance.new("Frame", track)
	slider.Size = UDim2.new(0, 20, 0, 20)
	slider.Position = UDim2.new(0, 2, 0, 2)
	slider.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	Instance.new("UICorner", slider).CornerRadius = UDim.new(1, 0)

	local function updateToggle(isEnabled)
		if isEnabled then
			track.BackgroundColor3 = Color3.fromRGB(80, 200, 80)
			statusLabel.Text = "ON"
			statusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
			slider:TweenPosition(UDim2.new(1, -22, 0, 2), Enum.EasingDirection.InOut, Enum.EasingStyle.Quad, 0.2, true)
		else
			track.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
			statusLabel.Text = "OFF"
			statusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
			slider:TweenPosition(UDim2.new(0, 2, 0, 2), Enum.EasingDirection.InOut, Enum.EasingStyle.Quad, 0.2, true)
		end
	end

	state:on(featureName, function(newState)
		updateToggle(newState)
	end)

	local function toggleFeature()
		state:toggle(featureName)
	end

	track.InputBegan:Connect(function(input, gp)
		if gp then return end
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			toggleFeature()
		end
	end)

	slider.InputBegan:Connect(function(input, gp)
		if gp then return end
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			toggleFeature()
		end
	end)

	updateToggle(state:get(featureName))
end

local function makeValueAdjuster(parent, ypos, minVal, maxVal, step, defaultVal, title, onChanged)
	-- (identical to previous version)
	local container = Instance.new("Frame", parent)
	container.Size = UDim2.new(1, -10, 0, 58)
	container.Position = UDim2.new(0, 5, 0, ypos)
	container.BackgroundColor3 = Color3.fromRGB(25, 28, 35)
	Instance.new("UICorner", container).CornerRadius = UDim.new(0, 10)

	local titleLbl = Instance.new("TextLabel", container)
	titleLbl.Size = UDim2.new(1, 0, 0, 22)
	titleLbl.Text = title
	titleLbl.TextColor3 = Color3.new(1, 1, 1)
	titleLbl.Font = Enum.Font.GothamBold
	titleLbl.TextSize = 14
	titleLbl.BackgroundTransparency = 1
	titleLbl.TextXAlignment = Enum.TextXAlignment.Center

	local valFrame = Instance.new("Frame", container)
	valFrame.Size = UDim2.new(0.35, 0, 0, 28)
	valFrame.Position = UDim2.new(0.325, 0, 0, 26)
	valFrame.BackgroundColor3 = Color3.fromRGB(35, 38, 45)
	Instance.new("UICorner", valFrame).CornerRadius = UDim.new(0, 8)

	local textbox = Instance.new("TextBox", valFrame)
	textbox.Size = UDim2.new(1, 0, 1, 0)
	textbox.BackgroundTransparency = 1
	textbox.Text = tostring(math.floor(defaultVal * 10) / 10)
	textbox.TextColor3 = Color3.fromRGB(100, 180, 255)
	textbox.Font = Enum.Font.GothamBold
	textbox.TextSize = 15
	textbox.TextXAlignment = Enum.TextXAlignment.Center
	textbox.ClearTextOnFocus = false
	textbox.MultiLine = false

	local minus = Instance.new("TextButton", container)
	minus.Size = UDim2.new(0.15, 0, 0, 28)
	minus.Position = UDim2.new(0.05, 0, 0, 26)
	minus.Text = "-"
	minus.BackgroundColor3 = Color3.fromRGB(45, 50, 55)
	minus.TextColor3 = Color3.new(1, 1, 1)
	minus.Font = Enum.Font.GothamBold
	minus.TextSize = 22
	Instance.new("UICorner", minus).CornerRadius = UDim.new(0, 8)

	local plus = Instance.new("TextButton", container)
	plus.Size = UDim2.new(0.15, 0, 0, 28)
	plus.Position = UDim2.new(0.8, 0, 0, 26)
	plus.Text = "+"
	plus.BackgroundColor3 = Color3.fromRGB(45, 50, 55)
	plus.TextColor3 = Color3.new(1, 1, 1)
	plus.Font = Enum.Font.GothamBold
	plus.TextSize = 22
	Instance.new("UICorner", plus).CornerRadius = UDim.new(0, 8)

	local current = defaultVal
	local function update(v)
		current = math.clamp(v, minVal, maxVal)
		local displayVal = math.floor(current * 100) / 100
		textbox.Text = tostring(displayVal)
		onChanged(current)
	end

	minus.MouseButton1Click:Connect(function() update(current - step) end)
	plus.MouseButton1Click:Connect(function() update(current + step) end)

	local function processTextInput()
		local inputValue = tonumber(textbox.Text)
		if inputValue then
			update(inputValue)
		else
			update(current)
		end
	end

	textbox.FocusLost:Connect(function() processTextInput() end)

	update(defaultVal)
end

-- KEYBIND BUTTON (unchanged)
local function makeKeybindButton(parent, ypos, currentKey, label)
	local btn = Instance.new("TextButton", parent)
	btn.Size = UDim2.new(1, -20, 0, 36)
	btn.Position = UDim2.new(0, 10, 0, ypos)
	btn.BackgroundColor3 = Color3.fromRGB(25, 28, 35)
	btn.Text = label .. ": " .. currentKey.Name
	btn.TextColor3 = Color3.new(1, 1, 1)
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 13
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
	return btn
end

local listening = nil
local conns = {}

local function setupKeybind(btn, name, label)
	btn.Activated:Connect(function()
		if listening == name then
			listening = nil
			btn.Text = label .. ": " .. keybinds[name].Name
			return
		end
		listening = name
		btn.Text = "Press any key..."
		if conns[name] then conns[name]:Disconnect() end
		conns[name] = UserInputService.InputBegan:Connect(function(inp, gp)
			if gp or inp.UserInputType ~= Enum.UserInputType.Keyboard then return end
			keybinds[name] = inp.KeyCode
			btn.Text = label .. ": " .. inp.KeyCode.Name
			listening = nil
			conns[name]:Disconnect()
		end)
	end)
end

local y = 10

-- STICKY
makeToggleSlider(Scroll, y, "Sticky", "sticky"); y += 56
local kb1 = makeKeybindButton(Scroll, y, keybinds.sticky, "Key"); y += 42
setupKeybind(kb1, "sticky", "Key")
makeValueAdjuster(Scroll, y, 0, 50, 0.01, pullStrength, "Pull Strength", function(v) pullStrength = v end); y += 64
makeValueAdjuster(Scroll, y, 0, 50, 0.01, stickiness, "Stickiness", function(v) stickiness = v end); y += 64
makeValueAdjuster(Scroll, y, 0, 50, 0.5, detectionRange, "Detection Range", function(v) detectionRange = v end); y += 64

-- HEAD BOOST
makeToggleSlider(Scroll, y, "Head Boost", "boost"); y += 56
local kb2 = makeKeybindButton(Scroll, y, keybinds.boost, "Key"); y += 42
setupKeybind(kb2, "boost", "Key")
makeValueAdjuster(Scroll, y, 10, 300, 5, boostPower, "Boost Power", function(v) boostPower = v end); y += 64

-- LOOP SPEED
makeToggleSlider(Scroll, y, "Loop Speed", "loop"); y += 56
local kb3 = makeKeybindButton(Scroll, y, keybinds.loop, "Key"); y += 42
setupKeybind(kb3, "loop", "Key")
makeValueAdjuster(Scroll, y, 0, 500, 0.2, loopSpeed, "WalkSpeed", function(v) loopSpeed = v end); y += 64

-- GRAVITY
makeToggleSlider(Scroll, y, "Gravity", "gravity"); y += 56
local kbJump = makeKeybindButton(Scroll, y, keybinds.gravity, "Key"); y += 42
setupKeybind(kbJump, "gravity", "Key")
makeValueAdjuster(Scroll, y, 0, 500, 1, gravityValue, "Gravity", function(v) gravityValue = v end); y += 64

-- HITBOX + GLOVES (same)
makeToggleSlider(Scroll, y, "Expand Hitbox", "hitbox"); y += 56
local kb5 = makeKeybindButton(Scroll, y, keybinds.hitbox, "Key"); y += 42
setupKeybind(kb5, "hitbox", "Key")
makeValueAdjuster(Scroll, y, 0, 200, 0.1, hitboxSize, "Hitbox Size", function(v) hitboxSize = v end); y += 64
makeValueAdjuster(Scroll, y, 0, 1, 0.05, hitboxTransparency, "Hitbox Transparency", function(v) hitboxTransparency = v end); y += 64

makeToggleSlider(Scroll, y, "Gloves", "gloves"); y += 56
local kb7 = makeKeybindButton(Scroll, y, keybinds.gloves, "Key"); y += 42
setupKeybind(kb7, "gloves", "Key")
makeValueAdjuster(Scroll, y, 0, 15, 0.1, gloveSize, "Glove Size", function(v) gloveSize = v end); y += 64
makeValueAdjuster(Scroll, y, 0, 1, 0.02, gloveTransparency, "Glove Transparency", function(v) gloveTransparency = v end); y += 64
makeToggleSlider(Scroll, y, "Invisible Gloves", "invisibleGloves"); y += 56

Scroll.CanvasSize = UDim2.new(0, 0, 0, y + 40)

-- INPUT HANDLING
UserInputService.InputBegan:Connect(function(i, p)
	if p then return end
	if i.KeyCode == Enum.KeyCode.F1 then
		Main.Visible = not Main.Visible
		OpenButton.Visible = not Main.Visible
	elseif i.KeyCode == keybinds.sticky then state:toggle("sticky")
	elseif i.KeyCode == keybinds.boost then state:toggle("boost")
	elseif i.KeyCode == keybinds.loop then state:toggle("loop")
	elseif i.KeyCode == keybinds.gravity then state:toggle("gravity")
	elseif i.KeyCode == keybinds.hitbox then state:toggle("hitbox")
	elseif i.KeyCode == keybinds.gloves then state:toggle("gloves")
	end
end)

-- HEAD BOOST, HITBOX, etc. (unchanged)
local function doBoost(rootPart)
	onCooldown = true
	cdRemaining = BOOST_COOLDOWN
	local bv = Instance.new("BodyVelocity")
	bv.Velocity = Vector3.new(0, boostPower, 0)
	bv.MaxForce = Vector3.new(0, 9e9, 0)
	bv.Parent = rootPart
	task.wait(0.2)
	bv:Destroy()
	task.delay(BOOST_COOLDOWN, function() onCooldown = false end)
end

local function feetOnHead(myHRP, theirHead)
	local myFeetY = myHRP.Position.Y - (myHRP.Size.Y / 2)
	local headTopY = theirHead.Position.Y + (theirHead.Size.Y / 2)
	local dy = myFeetY - headTopY
	if dy < -0.5 or dy > 2 then return false end
	local dx = math.abs(myHRP.Position.X - theirHead.Position.X)
	local dz = math.abs(myHRP.Position.Z - theirHead.Position.Z)
	return dx <= (theirHead.Size.X / 2 + 0.5) and dz <= (theirHead.Size.Z / 2 + 0.5)
end

local playerJumpStates = {}
local playerJumpTimers = {}

RunService.RenderStepped:Connect(function()
	if not state:get("hitbox") then return end
	for _, v in ipairs(Players:GetPlayers()) do
		if v ~= player then
			pcall(function()
				local hrp = v.Character and v.Character:FindFirstChild("HumanoidRootPart")
				if hrp then
					hrp.Size = Vector3.new(hitboxSize, hitboxSize, hitboxSize)
					hrp.Transparency = hitboxTransparency
					hrp.Material = Enum.Material.Neon
					hrp.CanCollide = true
				end
			end)
		end
	end
end)

-- MAIN GAME LOOP - ONLY SET SPEED WHEN LOOP IS ENABLED
RunService.Heartbeat:Connect(function(dt)
	if not root or not humanoid then return end

	-- WalkSpeed - ONLY override when Loop is ON (respects game's sprint)
	if state:get("loop") then
		humanoid.WalkSpeed = loopSpeed
	end

	-- Gravity
	Workspace.Gravity = state:get("gravity") and gravityValue or 196

	-- Head Boost, Sticky, Gloves (unchanged)
	if cdRemaining > 0 then cdRemaining = math.max(0, cdRemaining - dt) end
	if state:get("boost") and not onCooldown then
		-- ... (boost logic unchanged)
		local myChar = player.Character
		if myChar then
			local myHRP = myChar:FindFirstChild("HumanoidRootPart")
			if myHRP then
				for _, plr in ipairs(Players:GetPlayers()) do
					if plr ~= player then
						local char = plr.Character
						if char then
							local theirHead = char:FindFirstChild("Head")
							local hum = char:FindFirstChildOfClass("Humanoid")
							if theirHead and hum then
								local wasJumping = playerJumpStates[plr] or false
								local isJumping = hum.FloorMaterial == Enum.Material.Air
								if isJumping and not wasJumping then
									playerJumpTimers[plr] = 0.15
								end
								if playerJumpTimers[plr] and playerJumpTimers[plr] > 0 then
									playerJumpTimers[plr] = playerJumpTimers[plr] - dt
									if feetOnHead(myHRP, theirHead) then
										playerJumpTimers[plr] = 0
										doBoost(myHRP)
									end
								end
								playerJumpStates[plr] = isJumping
							end
						end
					end
				end
			end
		end
	end

	if state:get("sticky") then
		-- sticky logic unchanged
		local target = nil
		local minDist = math.huge
		for _, plr in Players:GetPlayers() do
			if plr ~= player and plr.Character then
				local hrpPart = plr.Character:FindFirstChild("HumanoidRootPart")
				if hrpPart then
					local d = (hrpPart.Position - root.Position).Magnitude
					if d < detectionRange and d < minDist then
						minDist = d
						target = plr
					end
				end
			end
		end
		if target and target.Character then
			local tRoot = target.Character:FindFirstChild("HumanoidRootPart")
			if tRoot then
				local offset = tRoot.Position - root.Position
				local d = offset.Magnitude
				if d <= detectionRange then
					if d > 3 and pullStrength > 0 then
						local vel = root.AssemblyLinearVelocity
						local dir = offset.Unit
						root.AssemblyLinearVelocity = Vector3.new(vel.X + (dir.X * pullStrength - vel.X) * 0.12, vel.Y, vel.Z + (dir.Z * pullStrength - vel.Z) * 0.12)
					end
					if stickiness > 0 then
						local lat = Vector3.new(offset.X, 0, offset.Z)
						if lat.Magnitude > 0.6 then
							root.AssemblyLinearVelocity += lat.Unit * stickiness * 0.55
						end
					end
				end
			end
		end
	end

	if state:get("gloves") then
		for _, handName in ipairs({"RightHand", "LeftHand"}) do
			local hand = character:FindFirstChild(handName)
			if hand then
				if not originalHandSizes[hand] then 
					originalHandSizes[hand] = hand.Size
					originalHandMaterials[hand] = hand.Material
					originalHandTransparencies[hand] = hand.Transparency
					originalHandCanCollides[hand] = hand.CanCollide
					originalHandColors[hand] = hand.Color
				end
				hand.Size = Vector3.new(gloveSize, gloveSize, gloveSize)
				hand.Transparency = state:get("invisibleGloves") and 1 or gloveTransparency
				hand.Material = Enum.Material.Plastic
				hand.Color = Color3.fromRGB(255, 0, 0)
				hand.CanCollide = false
				hand.TopSurface = Enum.SurfaceType.Smooth
				hand.BottomSurface = Enum.SurfaceType.Smooth
			end
		end
	else
		for hand, size in pairs(originalHandSizes) do
			if hand and hand.Parent then
				hand.Size = size
				hand.Material = originalHandMaterials[hand] or Enum.Material.Plastic
				hand.Transparency = originalHandTransparencies[hand] or 0
				hand.Color = originalHandColors[hand] or Color3.new(1, 1, 1)
				hand.CanCollide = originalHandCanCollides[hand] ~= false
				hand.TopSurface = Enum.SurfaceType.Brick
				hand.BottomSurface = Enum.SurfaceType.Brick
			end
		end
		originalHandSizes = {}
		originalHandMaterials = {}
		originalHandTransparencies = {}
		originalHandCanCollides = {}
		originalHandColors = {}
	end
end)

Players.PlayerRemoving:Connect(function(plr)
	playerJumpStates[plr] = nil
	playerJumpTimers[plr] = nil
end)

-- DEFAULTS AT BOTTOM
humanoid.WalkSpeed = 18
Workspace.Gravity = gravityValue

print("FLAME Hub Loaded! Press F1 to toggle menu - Sprint compatible")
