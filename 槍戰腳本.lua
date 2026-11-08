local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

repeat task.wait() until LocalPlayer and LocalPlayer.Character

local AimbotEnabled = false
local MaxDistance = 250
local AimPart = "Head"
local FovRadius = 150
local EspBoxEnabled = false
local EspLineEnabled = false
local EspNameEnabled = false
local EspChamsEnabled = false -- 新增：身體輪廓開關變數
local EspObjects = {}

local C = {
	bg = Color3.fromRGB(15, 8, 8),
	bg2 = Color3.fromRGB(25, 12, 12),
	bg3 = Color3.fromRGB(35, 18, 18),
	green = Color3.fromRGB(255, 40, 40),
	greenD = Color3.fromRGB(180, 30, 30),
	greenD2 = Color3.fromRGB(100, 20, 20),
	greenG = Color3.fromRGB(255, 60, 60),
	text = Color3.fromRGB(255, 180, 180),
	textD = Color3.fromRGB(120, 60, 60),
	red = Color3.fromRGB(255, 40, 40),
}

local function tw(obj, props, dur, ease)
	local ti = TweenInfo.new(dur or 0.3, ease or Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local t = TweenService:Create(obj, ti, props)
	t:Play()
	return t
end

local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
local dw = isMobile and 220 or 190
local dh = isMobile and 390 or 345 -- 微調：再加一行按鈕，拉高面板避免元件擠壓

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AimbotGUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = game.CoreGui
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local Frame = Instance.new("Frame", ScreenGui)
Frame.Size = UDim2.new(0, dw, 0, dh)
Frame.Position = UDim2.new(0.5, -dw/2, 0.5, -dh/2)
Frame.BackgroundColor3 = C.bg
Frame.BorderSizePixel = 0
Frame.ClipsDescendants = true
Frame.Active = true
Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 16)

local FrameStroke = Instance.new("UIStroke", Frame)
FrameStroke.Thickness = 1.5
FrameStroke.Color = C.green
FrameStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

local TopBar = Instance.new("Frame", Frame)
TopBar.Size = UDim2.new(1, 0, 0, 36)
TopBar.BackgroundColor3 = C.bg2
TopBar.BorderSizePixel = 0
Instance.new("UICorner", TopBar).CornerRadius = UDim.new(0, 16)

local Div = Instance.new("Frame", TopBar)
Div.Size = UDim2.new(1, -20, 0, 1)
Div.Position = UDim2.new(0, 10, 1, -1)
Div.BackgroundColor3 = C.greenD2
Div.BorderSizePixel = 0

local Title = Instance.new("TextLabel", TopBar)
Title.Size = UDim2.new(1, -50, 1, 0)
Title.Position = UDim2.new(0, 12, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "0101101"
Title.Font = Enum.Font.Code
Title.TextSize = isMobile and 14 or 13
Title.TextColor3 = C.green
Title.TextXAlignment = Enum.TextXAlignment.Left

task.spawn(function()
	while true do
		task.wait(0.15)
		local str = ""
		for i = 1, 12 do
			str = str .. math.random(0, 1)
		end
		Title.Text = "> " .. str
	end
end)

local MinBtn = Instance.new("TextButton", TopBar)
MinBtn.Size = UDim2.new(0, 26, 0, 26)
MinBtn.Position = UDim2.new(1, -32, 0, 5)
MinBtn.Text = "X"
MinBtn.Font = Enum.Font.GothamBold
MinBtn.TextSize = 18
MinBtn.TextColor3 = C.green
MinBtn.BackgroundColor3 = C.bg3
MinBtn.BackgroundTransparency = 0.3
MinBtn.BorderSizePixel = 0
MinBtn.AutoButtonColor = false
Instance.new("UICorner", MinBtn).CornerRadius = UDim.new(1, 0)

local Ball = Instance.new("TextButton", ScreenGui)
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
BallStroke.Color = C.green
BallStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

local BallLabel = Instance.new("TextLabel", Ball)
BallLabel.Size = UDim2.new(1, 0, 1, 0)
BallLabel.BackgroundTransparency = 1
BallLabel.Text = "呆"
BallLabel.Font = Enum.Font.GothamBold
BallLabel.TextSize = 24
BallLabel.TextColor3 = C.green
BallLabel.TextXAlignment = Enum.TextXAlignment.Center

local Content = Instance.new("Frame", Frame)
Content.Size = UDim2.new(1, -12, 1, -70)
Content.Position = UDim2.new(0, 6, 0, 40)
Content.BackgroundTransparency = 1
Content.BorderSizePixel = 0

local Layout = Instance.new("UIListLayout", Content)
Layout.Padding = UDim.new(0, 6)
Layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
Layout.SortOrder = Enum.SortOrder.LayoutOrder

local function makeBtn(text, color, order, fn)
	local b = Instance.new("TextButton")
	b.Size = UDim2.new(1, -4, 0, isMobile and 34 or 28)
	b.BackgroundColor3 = color
	b.BackgroundTransparency = 0.15
	b.BorderSizePixel = 0
	b.AutoButtonColor = false
	b.Text = ""
	b.LayoutOrder = order or 1
	b.Parent = Content
	Instance.new("UICorner", b).CornerRadius = UDim.new(0, 10)
	local st = Instance.new("UIStroke", b)
	st.Thickness = 1
	st.Color = C.green
	st.Transparency = 0.5
	st.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	local l = Instance.new("TextLabel", b)
	l.Size = UDim2.new(1, 0, 1, 0)
	l.BackgroundTransparency = 1
	l.Text = text
	l.Font = Enum.Font.SourceSans
	l.TextSize = isMobile and 14 or 13
	l.TextColor3 = C.text
	l.TextXAlignment = Enum.TextXAlignment.Center
	b.MouseButton1Click:Connect(function()
		if fn then fn(b, l) end
	end)
	return b, l
end

local function makeSlider(label, init, mn, mx, order, fn)
	local con = Instance.new("Frame", Content)
	con.Size = UDim2.new(1, -4, 0, isMobile and 42 or 34)
	con.BackgroundColor3 = C.bg3
	con.BackgroundTransparency = 0.2
	con.BorderSizePixel = 0
	con.LayoutOrder = order or 1
	Instance.new("UICorner", con).CornerRadius = UDim.new(0, 10)
	local sst = Instance.new("UIStroke", con)
	sst.Thickness = 1
	sst.Color = C.green
	sst.Transparency = 0.6
	sst.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	local sl = Instance.new("TextLabel", con)
	sl.Size = UDim2.new(1, -16, 0, 16)
	sl.Position = UDim2.new(0, 8, 0, 2)
	sl.BackgroundTransparency = 1
	sl.Text = label .. ": " .. init
	sl.Font = Enum.Font.SourceSans
	sl.TextSize = isMobile and 12 or 11
	sl.TextColor3 = C.textD
	sl.TextXAlignment = Enum.TextXAlignment.Left
	local sbg = Instance.new("Frame", con)
	sbg.Size = UDim2.new(1, -16, 0, 4)
	sbg.Position = UDim2.new(0, 8, 0, isMobile and 24 or 20)
	sbg.BackgroundColor3 = C.bg
	sbg.BorderSizePixel = 0
	Instance.new("UICorner", sbg).CornerRadius = UDim.new(1, 0)
	local sf = Instance.new("Frame", sbg)
	local fa = (mx - mn) > 0 and (init - mn) / (mx - mn) or 0
	sf.Size = UDim2.new(fa, 0, 1, 0)
	sf.BackgroundColor3 = C.green
	sf.BorderSizePixel = 0
	Instance.new("UICorner", sf).CornerRadius = UDim.new(1, 0)
	local knob = Instance.new("Frame", con)
	knob.Size = UDim2.new(0, 12, 0, 12)
	knob.Position = UDim2.new(fa, -6, 0, isMobile and 20 or 16)
	knob.BackgroundColor3 = C.greenG
	knob.BorderSizePixel = 0
	knob.ZIndex = 5
	Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)
	local ik = Instance.new("Frame", knob)
	ik.Size = UDim2.new(0, 6, 0, 6)
	ik.Position = UDim2.new(0.5, -3, 0.5, -3)
	ik.BackgroundColor3 = C.bg
	ik.BorderSizePixel = 0
	Instance.new("UICorner", ik).CornerRadius = UDim.new(1, 0)
	local val = init
	local sliderDragging = false
	local function upd(mx_pos)
		local ap = sbg.AbsolutePosition.X
		local as = sbg.AbsoluteSize.X
		if as <= 0 then return end
		local r = math.clamp((mx_pos - ap) / as, 0, 1)
		val = math.floor(r * (mx - mn) + mn)
		val = math.clamp(val, mn, mx)
		local clamped_r = (val - mn) / (mx - mn)
		sf.Size = UDim2.new(clamped_r, 0, 1, 0)
		sl.Text = label .. ": " .. val
		knob.Position = UDim2.new(clamped_r, -6, 0, isMobile and 20 or 16)
		if fn then fn(val) end
	end
	con.InputBegan:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
			sliderDragging = true
			upd(inp.Position.X)
		end
	end)
	knob.InputBegan:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
			sliderDragging = true
		end
	end)
	UserInputService.InputChanged:Connect(function(inp)
		if sliderDragging and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch) then
			upd(UserInputService:GetMouseLocation().X)
		end
	end)
	UserInputService.InputEnded:Connect(function(inp)
		if sliderDragging and (inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch) then
			sliderDragging = false
		end
	end)
	return con
end

makeBtn("[ 自動瞄準 ] OFF", C.red, 1, function(b, l)
	AimbotEnabled = not AimbotEnabled
	l.Text = "[ 自動瞄準 ] " .. (AimbotEnabled and "ON" or "OFF")
	local cor = AimbotEnabled and C.greenD or C.red
	tw(b, {BackgroundColor3 = cor}, 0.3)
end)

makeBtn("[ 瞄準部位 ] 頭部", C.greenD2, 2, function(b, l)
	if AimPart == "Head" then
		AimPart = "HumanoidRootPart"
		l.Text = "[ 瞄準部位 ] 身體"
	else
		AimPart = "Head"
		l.Text = "[ 瞄準部位 ] 頭部"
	end
end)

makeSlider("瞄準範圍", 150, 0, 1000, 3, function(v)
	FovRadius = v
end)

makeBtn("[ ESP方框 ] OFF", C.red, 4, function(b, l)
	EspBoxEnabled = not EspBoxEnabled
	l.Text = "[ ESP方框 ] " .. (EspBoxEnabled and "ON" or "OFF")
	local cor = EspBoxEnabled and C.greenD or C.red
	tw(b, {BackgroundColor3 = cor}, 0.3)
	for _, obj in pairs(EspObjects) do
		if obj.box then obj.box.Visible = EspBoxEnabled end
	end
end)

makeBtn("[ ESP線 ] OFF", C.red, 5, function(b, l)
	EspLineEnabled = not EspLineEnabled
	l.Text = "[ ESP線 ] " .. (EspLineEnabled and "ON" or "OFF")
	local cor = EspLineEnabled and C.greenD or C.red
	tw(b, {BackgroundColor3 = cor}, 0.3)
	for _, obj in pairs(EspObjects) do
		if obj.line then obj.line.Visible = EspLineEnabled end
	end
end)

makeBtn("[ ESP名字 ] OFF", C.red, 6, function(b, l)
	EspNameEnabled = not EspNameEnabled
	l.Text = "[ ESP名字 ] " .. (EspNameEnabled and "ON" or "OFF")
	local cor = EspNameEnabled and C.greenD or C.red
tw(b, {BackgroundColor3 = cor}, 0.3)
for _, obj in pairs(EspObjects) do
if obj.name then obj.name.Visible = EspNameEnabled end
end
end)
-- 【新增：獨立的 ESP 身體輪廓按鈕，排在 LayoutOrder 7】
makeBtn("[ ESP身體 ] OFF", C.red, 7, function(b, l)
EspChamsEnabled = not EspChamsEnabled
l.Text = "[ ESP身體 ] " .. (EspChamsEnabled and "ON" or "OFF")
local cor = EspChamsEnabled and C.greenD or C.red
tw(b, {BackgroundColor3 = cor}, 0.3)
for plr, obj in pairs(EspObjects) do
if obj.chams then
obj.chams.Enabled = (EspChamsEnabled and not isTeammate(plr))
end
end
end)
local Credit = Instance.new("TextLabel", Frame)
Credit.Size = UDim2.new(1, 0, 0, 26)
Credit.Position = UDim2.new(0, 0, 1, -26)
Credit.BackgroundColor3 = C.bg2
Credit.BackgroundTransparency = 0.5
Credit.BorderSizePixel = 0
Credit.Text = "槍戰自瞄通用腳本"
Credit.Font = Enum.Font.SourceSans
Credit.TextSize = 12
Credit.TextColor3 = C.textD
Credit.TextXAlignment = Enum.TextXAlignment.Center
Instance.new("UICorner", Credit).CornerRadius = UDim.new(0, 16)
local dragging = false
local dragObj = nil
local dragOffset = Vector2.new(0, 0)
local dragStartPos = UDim2.new(0, 0, 0, 0)
TopBar.InputBegan:Connect(function(input)
if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
dragging = true
dragObj = Frame
dragOffset = input.Position
dragStartPos = Frame.Position
end
end)
local function connectDrag(obj)
obj.InputBegan:Connect(function(input)
if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
dragging = true
dragObj = obj
dragOffset = input.Position
dragStartPos = obj.Position
end
end)
end
connectDrag(Ball)
UserInputService.InputChanged:Connect(function(input)
if dragging and dragObj and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
local delta = input.Position - dragOffset
dragObj.Position = UDim2.new(
dragStartPos.X.Scale, dragStartPos.X.Offset + delta.X,
dragStartPos.Y.Scale, dragStartPos.Y.Offset + delta.Y
)
end
end)
UserInputService.InputEnded:Connect(function(input)
if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
dragging = false
dragObj = nil
end
end)
local minimized = false
local function minimize()
minimized = true
Frame.Visible = false
MinBtn.Text = "X"
end
local function restore()
minimized = false
Frame.Visible = true
MinBtn.Text = "X"
end
MinBtn.MouseButton1Click:Connect(function()
if not minimized then minimize() else restore() end
end)
Ball.MouseButton1Click:Connect(function()
if not minimized then minimize() else restore() end
end)
local FovGui = Instance.new("ScreenGui")
FovGui.Name = "FovCircleGUI"
FovGui.ResetOnSpawn = false
FovGui.Parent = game.CoreGui
FovGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
FovGui.IgnoreGuiInset = true
local FovFrame = Instance.new("Frame")
FovFrame.Size = UDim2.new(0, 0, 0, 0)
FovFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
FovFrame.AnchorPoint = Vector2.new(0.5, 0.5)
FovFrame.BackgroundTransparency = 1
FovFrame.BorderSizePixel = 0
FovFrame.Parent = FovGui
FovFrame.Visible = false
local FovStroke = Instance.new("UIStroke", FovFrame)
FovStroke.Thickness = 2
FovStroke.Color = C.green
FovStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
local FovCorner = Instance.new("UICorner", FovFrame)
FovCorner.CornerRadius = UDim.new(1, 0)
local function isTeammate(targetPlayer)
if not targetPlayer then return false end
if LocalPlayer.Team and targetPlayer.Team and LocalPlayer.Team == targetPlayer.Team then
if LocalPlayer.Team.Name ~= "" then return true end
end
if LocalPlayer.Character and targetPlayer.Character then
local myArsenalTeam = LocalPlayer.Character:FindFirstChild("Team")
local enemyArsenalTeam = targetPlayer.Character:FindFirstChild("Team")
if myArsenalTeam and enemyArsenalTeam and myArsenalTeam.Value == enemyArsenalTeam.Value then
return true
end
end
return false
end
-- 【修改：建立 ESP 實例時同時建立 Highlight 輪廓透視】
local function createEsp(plr)
if plr == LocalPlayer then return end
local box = Drawing.new("Square")
box.Thickness = 1.5
box.Filled = false
box.Visible = false
local line = Drawing.new("Line")
line.Thickness = 1.5
line.Visible = false
local nameText = Drawing.new("Text")
nameText.Text = plr.Name
nameText.Size = 14
nameText.Center = true
nameText.Outline = true
nameText.OutlineColor = Color3.new(0, 0, 0)
nameText.Color = C.green
nameText.Visible = false
-- 新增 Highlight (輪廓)
local chams = Instance.new("Highlight")
chams.Name = "EspHighlight"
chams.FillColor = C.green
chams.FillTransparency = 0.6  -- 身體半透明度
chams.OutlineColor = Color3.new(1, 1, 1) -- 外框白色
chams.OutlineTransparency = 0 -- 外框不透明
chams.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop -- 穿牆可見
chams.Enabled = false
EspObjects[plr] = {box = box, line = line, name = nameText, chams = chams}
-- 如果玩家角色已經存在，直接綁定
if plr.Character then
chams.Adornee = plr.Character
chams.Parent = ScreenGui
end
-- 監聽角色重置/重生
plr.CharacterAdded:Connect(function(char)
task.wait(0.1)
if EspObjects[plr] and EspObjects[plr].chams then
EspObjects[plr].chams.Adornee = char
EspObjects[plr].chams.Parent = ScreenGui
EspObjects[plr].chams.Enabled = (EspChamsEnabled and not isTeammate(plr))
end
end)
end
Players.PlayerAdded:Connect(createEsp)
Players.PlayerRemoving:Connect(function(plr)
if EspObjects[plr] then
if EspObjects[plr].box then EspObjects[plr].box:Remove() end
if EspObjects[plr].line then EspObjects[plr].line:Remove() end
if EspObjects[plr].name then EspObjects[plr].name:Remove() end
if EspObjects[plr].chams then EspObjects[plr].chams:Destroy() end
EspObjects[plr] = nil
end
end)
for _, p in pairs(Players:GetPlayers()) do
createEsp(p)
end
local function getEspPart(char)
if not char then return nil end
if AimPart == "Head" then
return char:FindFirstChild("Head")
else
return char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Head")
end
end
RunService.RenderStepped:Connect(function()
if AimbotEnabled and FovRadius > 0 then
local size = FovRadius * 2
FovFrame.Size = UDim2.new(0, size, 0, size)
FovFrame.Visible = true
else
FovFrame.Visible = false
end
for plr, obj in pairs(EspObjects) do
if not obj.box or not obj.line or not obj.name or not obj.chams then continue end
local char = plr.Character
local hum = char and char:FindFirstChildOfClass("Humanoid")
local espPart = getEspPart(char)
if espPart and hum and hum.Health > 0 and not isTeammate(plr) then
local pos, onScreen = Camera:WorldToViewportPoint(espPart.Position)
-- 實時同步輪廓的開關與顯示
if EspChamsEnabled then
if obj.chams.Adornee ~= char then
obj.chams.Adornee = char
end
obj.chams.Enabled = true
else
obj.chams.Enabled = false
end
if onScreen then
local currentBoxSizeX, currentBoxSizeY = 10, 10
local currentBoxPosX, currentBoxPosY = pos.X - 5, pos.Y - 5
if AimPart == "HumanoidRootPart" then
local topPos = Camera:WorldToViewportPoint(espPart.Position + Vector3.new(0, 3, 0))
local bottomPos = Camera:WorldToViewportPoint(espPart.Position - Vector3.new(0, 3.5, 0))
currentBoxSizeY = math.abs(topPos.Y - bottomPos.Y)
currentBoxSizeX = currentBoxSizeY / 1.5
currentBoxPosX = pos.X - currentBoxSizeX / 2
currentBoxPosY = pos.Y - currentBoxSizeY / 2
end
-- 獨立控制：方框開關
if EspBoxEnabled then
obj.box.Size = Vector2.new(currentBoxSizeX, currentBoxSizeY)
obj.box.Position = Vector2.new(currentBoxPosX, currentBoxPosY)
obj.box.Color = C.green
obj.box.Visible = true
else
obj.box.Visible = false
end
-- 獨立控制：名字開關
if EspNameEnabled then
obj.name.Position = Vector2.new(pos.X, currentBoxPosY - 15)
obj.name.Color = C.green
obj.name.Visible = true
else
obj.name.Visible = false
end
-- 獨立控制：連線開關
if EspLineEnabled then
obj.line.From = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y)
obj.line.To = Vector2.new(pos.X, pos.Y)
obj.line.Color = C.green
obj.line.Visible = true
else
obj.line.Visible = false
end
else
obj.box.Visible = false
obj.line.Visible = false
obj.name.Visible = false
end
else
obj.box.Visible = false
obj.line.Visible = false
obj.name.Visible = false
obj.chams.Enabled = false
end
end
end)
local function isAlive(char)
local hum = char and char:FindFirstChildOfClass("Humanoid")
return hum and hum.Health > 0
end
local function visible(pos)
local origin = Camera.CFrame.Position
local dir = (pos - origin).Unit * (pos - origin).Magnitude
local params = RaycastParams.new()
params.FilterDescendantsInstances = {LocalPlayer.Character}
params.FilterType = Enum.RaycastFilterType.Blacklist
local result = workspace:Raycast(origin, dir, params)
if not result then return true end
return (result.Position - pos).Magnitude < 3
end
local function getBestTarget()
local best, bestDot = nil, -1
local screenCenter = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
for _, plr in pairs(Players:GetPlayers()) do
if plr ~= LocalPlayer and plr.Character and not isTeammate(plr) then
local part = plr.Character:FindFirstChild(AimPart) or plr.Character:FindFirstChild("Head")
if part and isAlive(plr.Character) then
local dist = (part.Position - Camera.CFrame.Position).Magnitude
if dist <= MaxDistance and visible(part.Position) then
local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)
if onScreen then
local screenVec = Vector2.new(screenPos.X, screenPos.Y)
local distFromCenter = (screenVec - screenCenter).Magnitude
if distFromCenter <= FovRadius then
local dir = (part.Position - Camera.CFrame.Position).Unit
local dot = Camera.CFrame.LookVector:Dot(dir)
if dot > bestDot then
bestDot = dot
best = part
end
end
end
end
end
end
end
return best
end
RunService.RenderStepped:Connect(function()
if not AimbotEnabled then return end
local target = getBestTarget()
if target then
Camera.CFrame = CFrame.new(Camera.CFrame.Position, target.Position)
end
end)
task.spawn(function()
pcall(function()
game:GetService("StarterGui"):SetCore("SendNotification", {
Title = "腳本載入成功🟢",
Text = "",
Duration = 4
})
end)
end)
