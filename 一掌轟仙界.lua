local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")
local VirtualInputManager = game:GetService("VirtualInputManager")
local GuiService = game:GetService("GuiService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")

-- 防止重複建立 UI
if PlayerGui:FindFirstChild("DarkRedFlyGUI") then
	PlayerGui.DarkRedFlyGUI:Destroy()
end

-- ==========================================
-- 0. Windows 實體鍵盤虛擬鍵碼對照表（供 keypress 使用）
-- ==========================================
local VK_MAP = {
	[Enum.KeyCode.A] = 0x41, [Enum.KeyCode.B] = 0x42, [Enum.KeyCode.C] = 0x43, [Enum.KeyCode.D] = 0x44,
	[Enum.KeyCode.E] = 0x45, [Enum.KeyCode.F] = 0x46, [Enum.KeyCode.G] = 0x47, [Enum.KeyCode.H] = 0x48,
	[Enum.KeyCode.I] = 0x49, [Enum.KeyCode.J] = 0x4A, [Enum.KeyCode.K] = 0x4B, [Enum.KeyCode.L] = 0x4C,
	[Enum.KeyCode.M] = 0x4D, [Enum.KeyCode.N] = 0x4E, [Enum.KeyCode.O] = 0x4F, [Enum.KeyCode.P] = 0x50,
	[Enum.KeyCode.Q] = 0x51, [Enum.KeyCode.R] = 0x52, [Enum.KeyCode.S] = 0x53, [Enum.KeyCode.T] = 0x54,
	[Enum.KeyCode.U] = 0x55, [Enum.KeyCode.V] = 0x56, [Enum.KeyCode.W] = 0x57, [Enum.KeyCode.X] = 0x58,
	[Enum.KeyCode.Y] = 0x59, [Enum.KeyCode.Z] = 0x5A,
	[Enum.KeyCode.Zero] = 0x30, [Enum.KeyCode.One] = 0x31, [Enum.KeyCode.Two] = 0x32, [Enum.KeyCode.Three] = 0x33,
	[Enum.KeyCode.Four] = 0x34, [Enum.KeyCode.Five] = 0x35, [Enum.KeyCode.Six] = 0x36, [Enum.KeyCode.Seven] = 0x37,
	[Enum.KeyCode.Eight] = 0x38, [Enum.KeyCode.Nine] = 0x39,
	[Enum.KeyCode.F1] = 0x70, [Enum.KeyCode.F2] = 0x71, [Enum.KeyCode.F3] = 0x72, [Enum.KeyCode.F4] = 0x73,
	[Enum.KeyCode.F5] = 0x74, [Enum.KeyCode.F6] = 0x75, [Enum.KeyCode.F7] = 0x76, [Enum.KeyCode.F8] = 0x77,
	[Enum.KeyCode.F9] = 0x78, [Enum.KeyCode.F10] = 0x79, [Enum.KeyCode.F11] = 0x7A, [Enum.KeyCode.F12] = 0x7B,
	[Enum.KeyCode.Space] = 0x20, [Enum.KeyCode.LeftShift] = 0xA0, [Enum.KeyCode.RightShift] = 0xA1,
	[Enum.KeyCode.LeftControl] = 0xA2, [Enum.KeyCode.RightControl] = 0xA3, [Enum.KeyCode.LeftAlt] = 0xA4,
	[Enum.KeyCode.Tab] = 0x09, [Enum.KeyCode.Backquote] = 0xC0, [Enum.KeyCode.Minus] = 0xBD, [Enum.KeyCode.Equals] = 0xBB
}

-- ==========================================
-- 1. 客戶端參數設定（拉桿 1 ~ 100，1 為基礎速度）
-- ==========================================
local startCFrame = rootPart.CFrame -- 紀錄初始位置為起點
local TRIGGER_KEY = Enum.KeyCode.F  -- 預設實體鍵盤觸發按鍵（可點擊右側微膠囊修改）
local isBindingKey = false
local isScriptPressing = false

local isFlying = false
local flyLockTime = 0
local flySpeedVal = 1  -- 拉桿數值（1 ~ 100）
local walkSpeedVal = 1 -- 拉桿數值（1 ~ 100）

local BASE_WALK_SPEED = 16
local BASE_FLY_SPEED = 60

-- 最大倍率上限設定（拉桿拉滿 100 時的實際倍數）
local MAX_WALK_MULT = 6
local MAX_FLY_MULT = 6

-- 全自動蓄力＋自動飛回整合開關
local AutoBeamEnabled = false
local TargetRatio = 0.985
local debounced = false
local debounceStartTime = 0

-- 設定牆壁偵測過濾器
local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude

-- 監聽玩家死亡重生時，自動更新角色組件並解除任何飛行鎖定
LocalPlayer.CharacterAdded:Connect(function(newChar)
	character = newChar
	humanoid = newChar:WaitForChild("Humanoid")
	rootPart = newChar:WaitForChild("HumanoidRootPart")
	isFlying = false
	debounced = false
end)

-- 核心客戶端位移推進迴圈
RunService.Heartbeat:Connect(function(dt)
	if isFlying and (tick() - flyLockTime > 12) then
		isFlying = false
	end
	if debounced and (tick() - debounceStartTime > 3) then
		debounced = false
	end

	if isFlying or walkSpeedVal <= 1 then return end
	if not character or not humanoid or not rootPart or humanoid.Health <= 0 then return end

	local moveDir = humanoid.MoveDirection
	if moveDir.Magnitude > 0 then
		local actualMultiplier = 1 + ((walkSpeedVal - 1) / 99) * (MAX_WALK_MULT - 1)
		local extraSpeed = BASE_WALK_SPEED * (actualMultiplier - 1)
		local step = moveDir * extraSpeed * dt

		rayParams.FilterDescendantsInstances = {character}
		local wallCheck = workspace:Raycast(rootPart.Position, moveDir * (step.Magnitude + 1.5), rayParams)

		if not wallCheck then
			rootPart.CFrame = rootPart.CFrame + step
		end
	end
end)

-- 通知輔助函式
local function sendNotify(title, text)
	pcall(function()
		StarterGui:SetCore("SendNotification", {
			Title = title,
			Text = text,
			Duration = 2.5
		})
	end)
end

-- 配色設定（黑紅科技風）
local C = {
	bg = Color3.fromRGB(15, 8, 8),
	bg2 = Color3.fromRGB(25, 12, 12),
	bg3 = Color3.fromRGB(35, 18, 18),
	redMain = Color3.fromRGB(255, 40, 40),
	redDark = Color3.fromRGB(100, 20, 20),
	text = Color3.fromRGB(255, 220, 220),
	textDim = Color3.fromRGB(180, 110, 110),
	btnRed = Color3.fromRGB(165, 28, 28),
	btnDarkRed = Color3.fromRGB(95, 22, 22),
	activeGreen = Color3.fromRGB(35, 175, 75),
	activeStroke = Color3.fromRGB(80, 255, 120),
	bindYellow = Color3.fromRGB(200, 140, 20)
}

local function tw(obj, props, dur, ease)
	local ti = TweenInfo.new(dur or 0.2, ease or Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local t = TweenService:Create(obj, ti, props)
	t:Play()
	return t
end

-- 偵測裝置尺寸（恢復原始標準大小）
local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
local btnHeight = isMobile and 36 or 32
local subHeaderHeight = 24
local dw = isMobile and 220 or 205
local dh = isMobile and (265 + btnHeight + 6 + subHeaderHeight) or (248 + btnHeight + 6 + subHeaderHeight)

-- ==========================================
-- 2. 建立黑紅科技風主視窗 UI（預設位置在螢幕正中間）
-- ==========================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "DarkRedFlyGUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = PlayerGui

local Frame = Instance.new("Frame", ScreenGui)
Frame.Name = "MainFrame"
Frame.Size = UDim2.new(0, dw, 0, dh)
Frame.Position = UDim2.new(0.5, -dw/2, 0.5, -dh/2)
Frame.BackgroundColor3 = C.bg
Frame.BorderSizePixel = 0
Frame.ClipsDescendants = true
Frame.Active = true
Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 16)

local FrameStroke = Instance.new("UIStroke", Frame)
FrameStroke.Thickness = 1.5
FrameStroke.Color = C.redMain
FrameStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

-- 頂部動態代碼列
local TopBar = Instance.new("Frame", Frame)
TopBar.Name = "TopBar"
TopBar.Size = UDim2.new(1, 0, 0, 34)
TopBar.BackgroundColor3 = C.bg2
TopBar.BorderSizePixel = 0
Instance.new("UICorner", TopBar).CornerRadius = UDim.new(0, 16)

local Title = Instance.new("TextLabel", TopBar)
Title.Size = UDim2.new(1, -50, 1, 0)
Title.Position = UDim2.new(0, 12, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "> 0101101"
Title.Font = Enum.Font.Code
Title.TextSize = isMobile and 14 or 13
Title.TextColor3 = C.redMain
Title.TextXAlignment = Enum.TextXAlignment.Left

task.spawn(function()
	while ScreenGui.Parent do
		task.wait(0.15)
		local str = ""
		for i = 1, 10 do
			str = str .. math.random(0, 1)
		end
		Title.Text = "> " .. str
	end
end)

-- 隱藏主視窗按鈕（X）
local MinBtn = Instance.new("TextButton", TopBar)
MinBtn.Size = UDim2.new(0, 24, 0, 24)
MinBtn.Position = UDim2.new(1, -30, 0, 5)
MinBtn.Text = "X"
MinBtn.Font = Enum.Font.GothamBold
MinBtn.TextSize = 15
MinBtn.TextColor3 = C.redMain
MinBtn.BackgroundColor3 = C.bg3
MinBtn.BackgroundTransparency = 0.3
MinBtn.BorderSizePixel = 0
MinBtn.AutoButtonColor = false
Instance.new("UICorner", MinBtn).CornerRadius = UDim.new(1, 0)

-- 專屬腳本名稱銘牌列（「一掌轟仙界腳本」）
local ScriptNameBar = Instance.new("Frame", Frame)
ScriptNameBar.Name = "ScriptNameBar"
ScriptNameBar.Size = UDim2.new(1, 0, 0, subHeaderHeight)
ScriptNameBar.Position = UDim2.new(0, 0, 0, 34)
ScriptNameBar.BackgroundColor3 = C.bg3
ScriptNameBar.BackgroundTransparency = 0.35
ScriptNameBar.BorderSizePixel = 0

local ScriptNameLabel = Instance.new("TextLabel", ScriptNameBar)
ScriptNameLabel.Size = UDim2.new(1, 0, 1, 0)
ScriptNameLabel.BackgroundTransparency = 1
ScriptNameLabel.Text = "⚔️ 一掌轟仙界腳本"
ScriptNameLabel.Font = Enum.Font.GothamBold
ScriptNameLabel.TextSize = isMobile and 13 or 12
ScriptNameLabel.TextColor3 = C.text
ScriptNameLabel.TextXAlignment = Enum.TextXAlignment.Center

local Div = Instance.new("Frame", ScriptNameBar)
Div.Size = UDim2.new(1, -20, 0, 1)
Div.Position = UDim2.new(0, 10, 1, -1)
Div.BackgroundColor3 = C.redDark
Div.BorderSizePixel = 0

-- ==========================================
-- 3. 「呆」字圓形懸浮球
-- ==========================================
local Ball = Instance.new("TextButton", ScreenGui)
Ball.Name = "FloatingBall"
Ball.Size = UDim2.new(0, 50, 0, 50)
Ball.Position = UDim2.new(0.5, -dw/2 - 60, 0.5, -25)
Ball.BackgroundColor3 = C.bg2
Ball.BorderSizePixel = 0
Ball.Visible = true
Ball.Text = ""
Ball.AutoButtonColor = false
Ball.ZIndex = 999
Instance.new("UICorner", Ball).CornerRadius = UDim.new(1, 0)

local BallStroke = Instance.new("UIStroke", Ball)
BallStroke.Thickness = 2
BallStroke.Color = C.redMain
BallStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

local BallLabel = Instance.new("TextLabel", Ball)
BallLabel.Size = UDim2.new(1, 0, 1, 0)
BallLabel.BackgroundTransparency = 1
BallLabel.Text = "呆"
BallLabel.Font = Enum.Font.GothamBold
BallLabel.TextSize = 24
BallLabel.TextColor3 = C.redMain
BallLabel.TextXAlignment = Enum.TextXAlignment.Center

-- ==========================================
-- 4. 精簡功能按鈕區（全自動蓄力 / 飛回起點 / 設為起點）
-- ==========================================
local contentStartY = 34 + subHeaderHeight + 8

local function makeFullButton(orderIndex, defaultText, bgColor, strokeColor, strokeTrans)
	local btn = Instance.new("TextButton", Frame)
	btn.Size = UDim2.new(1, -24, 0, btnHeight)
	btn.Position = UDim2.new(0, 12, 0, contentStartY + (btnHeight + 6) * orderIndex)
	btn.BackgroundColor3 = bgColor
	btn.BackgroundTransparency = 0.1
btn.BorderSizePixel = 0
btn.AutoButtonColor = false
btn.Text = ""
Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 10)
local stroke = Instance.new("UIStroke", btn)
stroke.Thickness = 1.2
stroke.Color = strokeColor
stroke.Transparency = strokeTrans
stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
local label = Instance.new("TextLabel", btn)
label.Size = UDim2.new(1, 0, 1, 0)
label.BackgroundTransparency = 1
label.Text = defaultText
label.Font = Enum.Font.GothamBold
label.TextSize = isMobile and 14 or 13
label.TextColor3 = C.text
return btn, stroke, label
end
-- 第 1 行：全自動蓄力開關
local AutoBeamBtn, AutoBeamStroke, AutoBeamLabel = makeFullButton(0, "[ 全自動蓄力 ] OFF", C.btnRed, C.redMain, 0.2)
-- 第 2 行：飛回起點按鈕（右側內嵌微膠囊快捷鍵標籤，預設 F）
local FlyBtn, FlyStroke, FlyLabel = makeFullButton(1, "🚀 飛回起點", C.btnRed, C.redMain, 0.2)
FlyLabel.Position = UDim2.new(0, -10, 0, 0)
local KeyBindBtn = Instance.new("TextButton", FlyBtn)
KeyBindBtn.Size = UDim2.new(0, 36, 0, btnHeight - 10)
KeyBindBtn.Position = UDim2.new(1, -42, 0.5, -(btnHeight - 10)/2)
KeyBindBtn.BackgroundColor3 = C.bg
KeyBindBtn.BackgroundTransparency = 0.65
KeyBindBtn.BorderSizePixel = 0
KeyBindBtn.AutoButtonColor = false
KeyBindBtn.Text = "[" .. TRIGGER_KEY.Name .. "]"
KeyBindBtn.Font = Enum.Font.Code
KeyBindBtn.TextSize = 11
KeyBindBtn.TextColor3 = Color3.fromRGB(255, 190, 190)
KeyBindBtn.ZIndex = FlyBtn.ZIndex + 2
Instance.new("UICorner", KeyBindBtn).CornerRadius = UDim.new(0, 6)
-- 第 3 行：設目前位置為起點
local SetStartBtn, SetStartStroke, SetStartLabel = makeFullButton(2, "📍 設目前位置為起點", C.btnDarkRed, C.redMain, 0.4)
-- ==========================================
-- 5. 建立通用拉桿（Slider）函式
-- ==========================================
local activeSlider = nil
local dragging = false
local function createSlider(yPos, labelPrefix, minVal, maxVal, defaultVal, onChanged)
local container = Instance.new("Frame", Frame)
container.Size = UDim2.new(1, -24, 0, 38)
container.Position = UDim2.new(0, 12, 0, yPos)
container.BackgroundTransparency = 1
local infoLabel = Instance.new("TextLabel", container)
infoLabel.Size = UDim2.new(1, 0, 0, 18)
infoLabel.Position = UDim2.new(0, 0, 0, 0)
infoLabel.BackgroundTransparency = 1
infoLabel.Text = labelPrefix .. ": " .. tostring(defaultVal) .. (defaultVal == 1 and " (基礎)" or "")
infoLabel.Font = Enum.Font.GothamBold
infoLabel.TextSize = isMobile and 12 or 11
infoLabel.TextColor3 = C.text
infoLabel.TextXAlignment = Enum.TextXAlignment.Left
local hitArea = Instance.new("TextButton", container)
hitArea.Size = UDim2.new(1, 0, 0, 20)
hitArea.Position = UDim2.new(0, 0, 0, 18)
hitArea.BackgroundTransparency = 1
hitArea.Text = ""
local track = Instance.new("Frame", hitArea)
track.Size = UDim2.new(1, 0, 0, 6)
track.Position = UDim2.new(0, 0, 0.5, -3)
track.BackgroundColor3 = C.bg3
track.BorderSizePixel = 0
Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)
local trackStroke = Instance.new("UIStroke", track)
trackStroke.Thickness = 1
trackStroke.Color = C.redDark
local initRatio = (defaultVal - minVal) / (maxVal - minVal)
local fill = Instance.new("Frame", track)
fill.Size = UDim2.new(initRatio, 0, 1, 0)
fill.BackgroundColor3 = C.redMain
fill.BorderSizePixel = 0
Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)
local knob = Instance.new("Frame", track)
knob.Size = UDim2.new(0, 14, 0, 14)
knob.Position = UDim2.new(initRatio, -7, 0.5, -7)
knob.BackgroundColor3 = C.text
knob.BorderSizePixel = 0
Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)
local knobStroke = Instance.new("UIStroke", knob)
knobStroke.Thickness = 1.5
knobStroke.Color = C.redMain
local function updateFromInput(inputPos)
local relX = math.clamp(inputPos.X - track.AbsolutePosition.X, 0, track.AbsoluteSize.X)
local ratio = relX / track.AbsoluteSize.X
local val = math.floor(minVal + ratio * (maxVal - minVal) + 0.5)
local snappedRatio = (val - minVal) / (maxVal - minVal)
fill.Size = UDim2.new(snappedRatio, 0, 1, 0)
knob.Position = UDim2.new(snappedRatio, -7, 0.5, -7)
infoLabel.Text = labelPrefix .. ": " .. tostring(val) .. (val == 1 and " (基礎)" or "")
onChanged(val)
end
hitArea.InputBegan:Connect(function(input)
if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
activeSlider = updateFromInput
updateFromInput(input.Position)
end
end)
end
local sliderStartY = contentStartY + (btnHeight * 3) + 20
-- 第一行拉桿：飛行速度 1 ~ 100
createSlider(sliderStartY, "⚡ 飛行速度", 1, 100, 1, function(val)
flySpeedVal = val
end)
-- 第二行拉桿：走路速度 1 ~ 100
createSlider(sliderStartY + 42, "👟 走路速度", 1, 100, 1, function(val)
walkSpeedVal = val
end)
-- 底部狀態標籤
local StatusLabel = Instance.new("TextLabel", Frame)
StatusLabel.Size = UDim2.new(1, 0, 0, 22)
StatusLabel.Position = UDim2.new(0, 0, 1, -22)
StatusLabel.BackgroundColor3 = C.bg2
StatusLabel.BackgroundTransparency = 0.5
StatusLabel.BorderSizePixel = 0
StatusLabel.Text = "狀態：待機中"
StatusLabel.Font = Enum.Font.SourceSansBold
StatusLabel.TextSize = 13
StatusLabel.TextColor3 = C.textDim
StatusLabel.TextXAlignment = Enum.TextXAlignment.Center
Instance.new("UICorner", StatusLabel).CornerRadius = UDim.new(0, 16)
-- ==========================================
-- 6. 核心平滑飛行與實體鍵盤按鍵模擬邏輯
-- ==========================================
local function flyToStart()
if isFlying then return end
local char = LocalPlayer.Character
local hum = char and char:FindFirstChildOfClass("Humanoid")
local hrp = char and char:FindFirstChild("HumanoidRootPart")
if not hum or hum.Health <= 0 or not hrp then return end
isFlying = true
flyLockTime = tick()
StatusLabel.Text = "狀態：✈️ 正在飛回起點..."
FlyLabel.Text = "✈️ 正在飛回起點..."
FlyLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
tw(FlyBtn, {BackgroundColor3 = C.activeGreen}, 0.2)
tw(FlyStroke, {Color = C.activeStroke}, 0.2)
pcall(function()
hum.PlatformStand = true
hrp.Anchored = true
local distance = (hrp.Position - startCFrame.Position).Magnitude
local actualFlyMult = 1 + ((flySpeedVal - 1) / 99) * (MAX_FLY_MULT - 1)
local currentFlySpeed = BASE_FLY_SPEED * actualFlyMult
local duration = math.clamp(distance / currentFlySpeed, 0.08, 8)
local tweenInfo = TweenInfo.new(
duration,
Enum.EasingStyle.Quad,
Enum.EasingDirection.Out
)
local tween = TweenService:Create(hrp, tweenInfo, {CFrame = startCFrame})
tween:Play()
tween.Completed:Wait()
end)
if hrp and hrp.Parent then
hrp.AssemblyLinearVelocity = Vector3.zero
hrp.Anchored = false
end
if hum and hum.Parent then
hum.PlatformStand = false
end
FlyLabel.Text = "🚀 飛回起點"
FlyLabel.TextColor3 = C.text
tw(FlyBtn, {BackgroundColor3 = C.btnRed}, 0.2)
tw(FlyStroke, {Color = C.redMain}, 0.2)
isFlying = false
StatusLabel.Text = "狀態：已抵達起點"
end
-- 實體鍵盤雙重按鍵模擬（無按鍵通知干擾）
local function pressConfiguredPhysicalKey()
StatusLabel.Text = "狀態：⌨️ 自動按下 [" .. TRIGGER_KEY.Name .. "] 鍵"
isScriptPressing = true
local vk = VK_MAP[TRIGGER_KEY]
if keypress and keyrelease and vk then
pcall(function()
keypress(vk)
task.wait(0.05)
keyrelease(vk)
end)
end
VirtualInputManager:SendKeyEvent(true, TRIGGER_KEY, false, game)
task.wait(0.05)
VirtualInputManager:SendKeyEvent(false, TRIGGER_KEY, false, game)
task.delay(0.15, function()
isScriptPressing = false
end)
end
FlyBtn.MouseButton1Click:Connect(function()
flyToStart()
end)
KeyBindBtn.MouseButton1Click:Connect(function()
if isBindingKey then return end
isBindingKey = true
KeyBindBtn.Text = "[...]"
KeyBindBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
tw(KeyBindBtn, {BackgroundColor3 = C.bindYellow, BackgroundTransparency = 0.2}, 0.15)
sendNotify("設定快捷鍵", "請按下鍵盤上要綁定的新按鍵（按 ESC 取消）")
end)
UserInputService.InputBegan:Connect(function(input, gameProcessed)
if isBindingKey then
if input.UserInputType == Enum.UserInputType.Keyboard then
if input.KeyCode ~= Enum.KeyCode.Escape and input.KeyCode ~= Enum.KeyCode.Unknown then
TRIGGER_KEY = input.KeyCode
sendNotify("快捷鍵已更新", "已將飛回快捷鍵設為 [" .. TRIGGER_KEY.Name .. "]")
end
isBindingKey = false
KeyBindBtn.Text = "[" .. TRIGGER_KEY.Name .. "]"
KeyBindBtn.TextColor3 = Color3.fromRGB(255, 190, 190)
tw(KeyBindBtn, {BackgroundColor3 = C.bg, BackgroundTransparency = 0.65}, 0.15)
end
return
end
if input.KeyCode == TRIGGER_KEY then
if isScriptPressing or not gameProcessed then
flyToStart()
end
end
end)
SetStartBtn.MouseButton1Click:Connect(function()
local char = LocalPlayer.Character
local hrp = char and char:FindFirstChild("HumanoidRootPart")
if hrp then
startCFrame = hrp.CFrame
sendNotify("起點已更新", "已將目前腳下位置設為新的起點！")
SetStartLabel.Text = "✅ 起點設定成功！"
tw(SetStartBtn, {BackgroundColor3 = C.activeGreen}, 0.15)
tw(SetStartStroke, {Color = C.activeStroke}, 0.15)
task.delay(1.2, function()
SetStartLabel.Text = "📍 設目前位置為起點"
tw(SetStartBtn, {BackgroundColor3 = C.btnDarkRed}, 0.25)
tw(SetStartStroke, {Color = C.redMain}, 0.25)
end)
end
end)
-- ==========================================
-- 7. 全自動蓄力＋結算自動按鍵盤飛回整合循環
-- ==========================================
local function isPointInsideGui(guiObj, x, y)
if not guiObj or not guiObj.Visible then return false end
local p = guiObj.AbsolutePosition
local s = guiObj.AbsoluteSize
return x >= (p.X - 10) and x <= (p.X + s.X + 10) and y >= (p.Y - 10) and y <= (p.Y + s.Y + 10)
end
local function clickScreenCenter()
if dragging or activeSlider or isFlying then return end
local cam = Workspace.CurrentCamera
if not cam then return end
local vp = cam.ViewportSize
local cx = vp.X * 0.5
local cy = vp.Y * 0.5
if isPointInsideGui(Frame, cx, cy) or isPointInsideGui(Ball, cx, cy) then
cx = vp.X * 0.8
if isPointInsideGui(Frame, cx, cy) or isPointInsideGui(Ball, cx, cy) then
cx = vp.X * 0.2
end
end
VirtualInputManager:SendMouseButtonEvent(cx, cy, 0, true, game, 1)
task.wait(0.03)
VirtualInputManager:SendMouseButtonEvent(cx, cy, 0, false, game, 1)
end
local function clickGuiButton(button)
if firesignal then
pcall(function() firesignal(button.MouseButton1Click) end)
pcall(function() firesignal(button.Activated) end)
end
local pos = button.AbsolutePosition
local size = button.AbsoluteSize
local inset = GuiService:GetGuiInset()
local centerX = pos.X + (size.X / 2) + inset.X
local centerY = pos.Y + (size.Y / 2) + inset.Y
VirtualInputManager:SendMouseButtonEvent(centerX, centerY, 0, true, game, 1)
task.wait(0.02)
VirtualInputManager:SendMouseButtonEvent(centerX, centerY, 0, false, game, 1)
end
local function isActuallyVisible(obj)
local curr = obj
while curr and curr ~= PlayerGui do
if curr:IsA("GuiObject") and not curr.Visible then
return false
elseif curr:IsA("LayerCollector") and not curr.Enabled then
return false
end
curr = curr.Parent
end
return true
end
local function findFireButton()
for _, obj in ipairs(PlayerGui:GetDescendants()) do
if obj:IsDescendantOf(ScreenGui) then continue end
if (obj:IsA("TextButton") or obj:IsA("ImageButton")) and isActuallyVisible(obj) then
if obj:IsA("TextButton") and string.find(obj.Text, "發") then return obj end
for _, child in ipairs(obj:GetDescendants()) do
if child:IsA("TextLabel") and string.find(child.Text, "發") then return obj end
end
end
end
return nil
end
local function findPointer(container)
local bestCandidate = nil
for _, obj in ipairs(container:GetDescendants()) do
if obj:IsA("Frame") and obj.Visible then
if obj.AbsoluteSize.X >= 1 and obj.AbsoluteSize.X <= 25 and obj.AbsoluteSize.Y >= 12 then
bestCandidate = obj
end
end
end
return bestCandidate
end
local function getSettlementInfo()
local keywords = {"繼續", "點擊以", "確定", "領取", "返回", "重來"}
for _, obj in ipairs(PlayerGui:GetDescendants()) do
if obj:IsDescendantOf(ScreenGui) then continue end
if (obj:IsA("TextLabel") or obj:IsA("TextButton")) and isActuallyVisible(obj) then
local txt = obj.Text
if txt and txt ~= "" then
for _, kw in ipairs(keywords) do
if string.find(txt, kw) then
local btn = obj:IsA("TextButton") and obj or obj:FindFirstAncestorWhichIsA("GuiButton")
return true, btn
end
end
end
end
end
return false, nil
end
-- 第 1 行：全自動蓄力開關
AutoBeamBtn.MouseButton1Click:Connect(function()
AutoBeamEnabled = not AutoBeamEnabled
isFlying = false
debounced = false
AutoBeamLabel.Text = "[ 全自動蓄力 ] " .. (AutoBeamEnabled and "ON" or "OFF")
if AutoBeamEnabled then
AutoBeamLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
tw(AutoBeamBtn, {BackgroundColor3 = C.activeGreen}, 0.25)
tw(AutoBeamStroke, {Color = C.activeStroke}, 0.25)
else
AutoBeamLabel.TextColor3 = C.text
tw(AutoBeamBtn, {BackgroundColor3 = C.btnRed}, 0.25)
tw(AutoBeamStroke, {Color = C.redMain}, 0.25)
StatusLabel.Text = "狀態：待機中"
end
end)
-- 高速偵測蓄力條並於 0.985 發射
RunService.RenderStepped:Connect(function()
if not AutoBeamEnabled or debounced or isFlying then return end
local fireBtn = findFireButton()
if fireBtn and fireBtn.Parent then
StatusLabel.Text = "狀態：⚡ 蓄力偵測中..."
local rootPanel = fireBtn.Parent.Parent or fireBtn.Parent
local pointer = findPointer(rootPanel)
if pointer and pointer.Parent then
local barWidth = pointer.Parent.AbsoluteSize.X
if barWidth > 0 then
local pointerCenterX = (pointer.AbsolutePosition.X + (pointer.AbsoluteSize.X / 2)) - pointer.Parent.AbsolutePosition.X
local ratio = pointerCenterX / barWidth
if ratio >= TargetRatio then
debounced = true
debounceStartTime = tick()
StatusLabel.Text = "狀態：🔥 完美發射！"
clickGuiButton(fireBtn)
task.wait(0.8)
debounced = false
end
end
end
end
end)
-- 背景循環：結算清理 → 自動按鍵盤飛回起點 → 自動點擊下一輪蓄力
task.spawn(function()
while ScreenGui.Parent do
task.wait(0.35)
if not AutoBeamEnabled or debounced or isFlying then continue end
local fireBtn = findFireButton()
if fireBtn then continue end
local hasSettle, settleBtn = getSettlementInfo()
if hasSettle then
StatusLabel.Text = "狀態：🎯 偵測到結算畫面"
for i = 1, 6 do
local stillOpen, currentBtn = getSettlementInfo()
if not stillOpen then break end
if currentBtn then
clickGuiButton(currentBtn)
end
clickScreenCenter()
task.wait(0.35)
end
task.wait(1.0)
if AutoBeamEnabled then
pressConfiguredPhysicalKey()
task.wait(0.25)
while isFlying do
task.wait(0.1)
end
end
if AutoBeamEnabled and not findFireButton() then
task.wait(0.2)
clickScreenCenter()
end
else
StatusLabel.Text = "狀態：👆 點擊螢幕開始蓄力"
clickScreenCenter()
task.wait(0.5)
end
end
end)
-- ==========================================
-- 8. 拖曳與開關邏輯
-- ==========================================
local dragObj, dragOffset, dragStartPos = nil, Vector2.new(0, 0), UDim2.new(0, 0, 0, 0)
local hasMoved = false
local function startWindowDrag(input)
if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
dragging = true
dragObj = Frame
dragOffset = input.Position
dragStartPos = Frame.Position
end
end
TopBar.InputBegan:Connect(startWindowDrag)
ScriptNameBar.InputBegan:Connect(startWindowDrag)
Ball.InputBegan:Connect(function(input)
if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
dragging = true
hasMoved = false
dragObj = Ball
dragOffset = input.Position
dragStartPos = Ball.Position
end
end)
UserInputService.InputChanged:Connect(function(input)
if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
if activeSlider then
activeSlider(input.Position)
return
end
if dragging and dragObj then
local delta = input.Position - dragOffset
if delta.Magnitude > 5 then
hasMoved = true
end
dragObj.Position = UDim2.new(dragStartPos.X.Scale, dragStartPos.X.Offset + delta.X, dragStartPos.Y.Scale, dragStartPos.Y.Offset + delta.Y)
end
end
end)
UserInputService.InputEnded:Connect(function(input)
if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
activeSlider = nil
dragging = false
dragObj = nil
end
end)
MinBtn.MouseButton1Click:Connect(function()
Frame.Visible = false
end)
Ball.MouseButton1Click:Connect(function()
if hasMoved then return end
Frame.Visible = not Frame.Visible
end)
-- 載入成功系統提示
sendNotify("腳本載入成功🟢", "一掌轟仙界腳本已就緒！")
