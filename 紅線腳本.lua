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
local AimKey = Enum.KeyCode.Q -- 預設觸發按鍵為 Q 鍵

local EspBoxEnabled = false   
local EspLineEnabled = false  
local EspNameEnabled = false  
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
local dh = isMobile and 390 or 350 

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
    knob.BackgroundColor3 = C.greenG knob.BorderSizePixel = 0 
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

local function makeKeyInput(label, defaultKey, order, fn) 
    local con = Instance.new("Frame", Content) 
    con.Size = UDim2.new(1, -4, 0, isMobile and 34 or 28) 
    con.BackgroundColor3 = C.bg3 
    con.BackgroundTransparency = 0.2 
    con.BorderSizePixel = 0 
    con.LayoutOrder = order or 7 
    Instance.new("UICorner", con).CornerRadius = UDim.new(0, 10) 
    
    local st = Instance.new("UIStroke", con) 
    st.Thickness = 1 
    st.Color = C.green 
    st.Transparency = 0.5 
    st.ApplyStrokeMode = Enum.ApplyStrokeMode.Border 
local lbl = Instance.new("TextLabel", con)
lbl.Size = UDim2.new(0.5, 0, 1, 0)
lbl.Position = UDim2.new(0, 8, 0, 0)
lbl.BackgroundTransparency = 1
lbl.Text = label
lbl.Font = Enum.Font.SourceSans
lbl.TextSize = isMobile and 13 or 12
lbl.TextColor3 = C.textD
lbl.TextXAlignment = Enum.TextXAlignment.Left
local box = Instance.new("TextBox", con)
box.Size = UDim2.new(0.4, -4, 1, -6)
box.Position = UDim2.new(0.6, 0, 0, 3)
box.BackgroundColor3 = C.bg
box.Text = tostring(defaultKey)
box.Font = Enum.Font.Code
box.TextSize = isMobile and 13 or 12
box.TextColor3 = C.green
box.PlaceholderText = "按鍵"
Instance.new("UICorner", box).CornerRadius = UDim.new(0, 6)
local bst = Instance.new("UIStroke", box)
bst.Thickness = 1
bst.Color = C.greenD2
bst.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
box.FocusLost:Connect(function(enterPressed)
local inputStr = box.Text:upper()
if inputStr == "" then return end
local success, code = pcall(function() return Enum.KeyCode[inputStr] end)
if success and code then
box.Text = inputStr
if fn then fn(code) end
else
box.Text = tostring(AimKey.Name)
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
local cor
EspLineEnabled = not EspLineEnabled
l.Text = "[ ESP線 ] " .. (EspLineEnabled and "ON" or "OFF")
if EspLineEnabled then cor = C.greenD else cor = C.red end
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
makeKeyInput("自瞄鎖定按鍵", "Q", 7, function(newKeyCode)
AimKey = newKeyCode
end)
-- 【修正完畢：內容換回 REDLINER DEV，顏色保持 textD，字體放大到 15 級】
local Credit = Instance.new("TextLabel", Frame)
Credit.Size = UDim2.new(1, 0, 0, 26)
Credit.Position = UDim2.new(0, 0, 1, -26)
Credit.BackgroundColor3 = C.bg2
Credit.BackgroundTransparency = 0.5
Credit.BorderSizePixel = 0
Credit.Text = "REDLINER DEV"
Credit.Font = Enum.Font.SourceSans -- 保持原本乾淨的字體風格
Credit.TextSize = 15               -- 修改：大小調大到 15 級
Credit.TextColor3 = C.textD        -- 保持：原本的暗紅色/灰色不變
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
dragStartPos.X.Scale,
dragStartPos.X.Offset + delta.X,
dragStartPos.Y.Scale,
dragStartPos.Y.Offset + delta.Y
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
if not minimized then
minimize()
else
restore()
end
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
EspObjects[plr] = {box = box, line = line, name = nameText}
end
Players.PlayerAdded:Connect(createEsp)
Players.PlayerRemoving:Connect(function(plr)
if EspObjects[plr] then
if EspObjects[plr].box then EspObjects[plr].box:Remove() end
if EspObjects[plr].line then EspObjects[plr].line:Remove() end
if EspObjects[plr].name then EspObjects[plr].name:Remove() end
EspObjects[plr] = nil
end
end)
for _, p in pairs(Players:GetPlayers()) do createEsp(p) end
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
FovFrame.Position = UDim2.new(0, UserInputService:GetMouseLocation().X, 0, UserInputService:GetMouseLocation().Y)
FovFrame.Visible = true
else
FovFrame.Visible = false
end
for plr, obj in pairs(EspObjects) do
if not obj.box or not obj.line or not obj.name then continue end
local char = plr.Character
local hum = char and char:FindFirstChildOfClass("Humanoid")
local espPart = getEspPart(char)
if espPart and hum and hum.Health > 0 and not isTeammate(plr) then
local pos, onScreen = Camera:WorldToViewportPoint(espPart.Position)
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
if EspBoxEnabled then
obj.box.Size = Vector2.new(currentBoxSizeX, currentBoxSizeY)
obj.box.Position = Vector2.new(currentBoxPosX, currentBoxPosY)
obj.box.Color = C.green
obj.box.Visible = true
else obj.box.Visible = false end
if EspNameEnabled then
obj.name.Position = Vector2.new(pos.X, currentBoxPosY - 15)
obj.name.Color = C.green
obj.name.Visible = true
else obj.name.Visible = false end
if EspLineEnabled then
obj.line.From = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y)
obj.line.To = Vector2.new(pos.X, pos.Y)
obj.line.Color = C.green
obj.line.Visible = true
else obj.line.Visible = false end
else
obj.box.Visible = false; obj.line.Visible = false; obj.name.Visible = false
end
else
obj.box.Visible = false; obj.line.Visible = false; obj.name.Visible = false
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
local isKeyDown = UserInputService:IsKeyDown(AimKey)
if isKeyDown then
local target = getBestTarget()
if target then
Camera.CFrame = CFrame.new(Camera.CFrame.Position, target.Position)
end
end
end)
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

repeat task.wait() until LocalPlayer and LocalPlayer.Character

local Config = {
    AutoStick = false,
    AutoAttack = false,
    TargetMode = "NPC",
    AimlockEnabled = false,
}

local MaxDistance = 1500      
local AttackDistance = 2.5    
local AimlockTargetChar = nil 
local IsLockingCamera = false 
local CurrentClosestTarget = nil 
local CurrentStickTarget = nil 

local LostTargetTime = 0
local TargetGracePeriod = 2.5 

local npcCache = setmetatable({}, { __mode = "k" })
local function registerNPC(model)
    if not model or not model:IsA("Model") then return end
    if model == LocalPlayer.Character then return end
    if Players:GetPlayerFromCharacter(model) then return end
    local hum = model:FindFirstChildOfClass("Humanoid")
    local hrp = model:FindFirstChild("HumanoidRootPart") or model:FindFirstChild("Torso")
    if hum and hrp then npcCache[model] = true end
end

for _, desc in ipairs(workspace:GetDescendants()) do
    if desc:IsA("Humanoid") and desc.Parent and desc.Parent:IsA("Model") then registerNPC(desc.Parent) end
end
workspace.DescendantAdded:Connect(function(desc)
    if desc:IsA("Humanoid") and desc.Parent and desc.Parent:IsA("Model") then registerNPC(desc.Parent)
    elseif desc:IsA("Model") then task.defer(function() registerNPC(desc) end) end
end)

local cachedLobby = workspace:FindFirstChild("Lobby")
local function isInsideLobby(targetPart)
    if not targetPart then return true end
    local char = targetPart:IsA("Model") and targetPart or targetPart:FindFirstAncestorOfClass("Model")
    if not char then return false end
    if not cachedLobby or not cachedLobby.Parent then cachedLobby = workspace:FindFirstChild("Lobby") end
    if cachedLobby and char:IsDescendantOf(cachedLobby) then return true end
    return false
end

local function getStickTarget()
    if CurrentStickTarget and CurrentStickTarget.Parent then
        local hum = CurrentStickTarget:FindFirstChildOfClass("Humanoid")
        local hrp = CurrentStickTarget:FindFirstChild("HumanoidRootPart") or CurrentStickTarget:FindFirstChild("Torso")
        if hum and hrp and hum.Health > 0 and not isInsideLobby(hrp) then
            return CurrentStickTarget
        end
    end

    local myChar = LocalPlayer.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not myRoot then return nil end

    local bestTarget, shortestDistance = nil, math.huge

    for _, obj in ipairs(workspace:GetChildren()) do
        if obj:IsA("Model") and obj ~= myChar then
            local hum = obj:FindFirstChildOfClass("Humanoid")
            local hrp = obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChild("Torso")
            if hum and hrp and hum.Health > 0 and not isInsideLobby(hrp) then
                local worldDist = (hrp.Position - myRoot.Position).Magnitude
                if worldDist <= MaxDistance then
                    local yHeightDiff = math.abs(hrp.Position.Y - myRoot.Position.Y)
                    if yHeightDiff < 35 then
                        local isPlayer = Players:GetPlayerFromCharacter(obj) ~= nil
                        if (Config.TargetMode == "Player" and isPlayer) or (Config.TargetMode == "NPC" and not isPlayer and npcCache[obj]) then
                            if worldDist < shortestDistance then 
                                shortestDistance = worldDist
                                bestTarget = obj 
                            end
                        end
                    end
                end
            end
        end
    end
    CurrentStickTarget = bestTarget
    return bestTarget
end

local function getFrontClosestTarget()
    local myChar = LocalPlayer.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not myRoot then return nil end
    
    Camera = workspace.CurrentCamera
    if not Camera then return nil end
    
    local camPos = Camera.CFrame.Position
    local camLook = Camera.CFrame.LookVector
    
    local bestTarget = nil
    local shortestDistance = math.huge

    for _, obj in ipairs(workspace:GetChildren()) do
        if obj:IsA("Model") and obj ~= myChar then
            local hum = obj:FindFirstChildOfClass("Humanoid")
            local hrp = obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChild("Torso")
            if hum and hrp and hum.Health > 0 and not isInsideLobby(hrp) then
                local offset = hrp.Position - camPos
                local dist = offset.Magnitude
                if dist <= MaxDistance then
                    local yHeightDiff = hrp.Position.Y - myRoot.Position.Y
                    if yHeightDiff > -14 then
                        local dot = camLook:Dot(offset.Unit)
                        if dot > 0.4 then 
                            local isPlayer = Players:GetPlayerFromCharacter(obj) ~= nil
                            if (Config.TargetMode == "Player" and isPlayer) or (Config.TargetMode == "NPC" and not isPlayer and npcCache[obj]) then
                                if dist < shortestDistance then 
                                    shortestDistance = dist
                                    bestTarget = obj
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    return bestTarget
end

task.spawn(function()
    while true do
        task.wait(0.03)
        CurrentClosestTarget = getFrontClosestTarget()
        
        if IsLockingCamera and AimlockTargetChar then
            if not AimlockTargetChar.Parent then
                IsLockingCamera = false
                AimlockTargetChar = nil
                aimlockFloatBtn.Text = "未鎖定"
                continue
            end
            local hum = AimlockTargetChar:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health <= 0 then
                IsLockingCamera = false
                AimlockTargetChar = nil
                aimlockFloatBtn.Text = "未鎖定"
            end
        end
    end
end)

LocalPlayer.CharacterAdded:Connect(function(char)
    CurrentStickTarget = nil
    AimlockTargetChar = nil
    IsLockingCamera = false
end)

local C = { 
    bg = Color3.fromRGB(15, 8, 8),       
    bg2 = Color3.fromRGB(25, 12, 12),     
    bg3 = Color3.fromRGB(35, 18, 18),     
    green = Color3.fromRGB(255, 40, 40),   
    greenD = Color3.fromRGB(180, 30, 30),  
    greenD2 = Color3.fromRGB(100, 20, 20), 
    purpleBorder = Color3.fromRGB(150, 90, 255), 
    text = Color3.fromRGB(255, 180, 180),  
    textD = Color3.fromRGB(120, 60, 60),   
} 

local function tw(obj, props, dur, ease) 
    local ti = TweenInfo.new(dur or 0.3, ease or Enum.EasingStyle.Quad, Enum.EasingDirection.Out) 
    local t = TweenService:Create(obj, ti, props) 
    t:Play() 
    return t 
end 

local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled 
local dw = isMobile and 260 or 230 
local dh = isMobile and 285 or 255 

local ScreenGui = Instance.new("ScreenGui") 
ScreenGui.Name = "SolaraInternalGUI" 
ScreenGui.ResetOnSpawn = false 
ScreenGui.Parent = game:GetService("CoreGui")
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
TopBar.Size = UDim2.new(1, 0, 0, 38) 
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
Title.TextSize = isMobile and 15 or 14 
Title.TextColor3 = C.green 
Title.TextXAlignment = Enum.TextXAlignment.Left 

task.spawn(function() 
    while true do 
        task.wait(0.15) 
        local str = "" 
        for i = 1, 12 do str = str .. math.random(0, 1) end 
        Title.Text = "> " .. str 
    end 
end) 

local MinBtn = Instance.new("TextButton", TopBar) 
MinBtn.Size = UDim2.new(0, 28, 0, 28) 
MinBtn.Position = UDim2.new(1, -34, 0, 5) 
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
Ball.Size = UDim2.new(0, 48, 0, 48) 
Ball.Position = UDim2.new(0.5, -dw/2 - 50, 0.5, -24) 
Ball.BackgroundColor3 = C.bg2 
Ball.BorderSizePixel = 0 
Ball.Visible = true 
Ball.Text = "" 
Ball.AutoButtonColor = false 
Ball.ZIndex = 1000 
Instance.new("UICorner", Ball).CornerRadius = UDim.new(1, 0) 

local BallStroke = Instance.new("UIStroke", Ball) 
BallStroke.Thickness = 1.5 
BallStroke.Color = C.green 
BallStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border 

local BallLabel = Instance.new("TextLabel", Ball)
BallLabel.Size = UDim2.new(1, 0, 1, 0)
BallLabel.BackgroundTransparency = 1
BallLabel.Text = "⚡"
BallLabel.Font = Enum.Font.GothamBold
BallLabel.TextSize = 24
BallLabel.TextColor3 = C.green
BallLabel.TextXAlignment = Enum.TextXAlignment.Center
local Content = Instance.new("Frame", Frame)
Content.Size = UDim2.new(1, -14, 1, -85)
Content.Position = UDim2.new(0, 7, 0, 46)
Content.BackgroundTransparency = 1
Content.BorderSizePixel = 0
local Layout = Instance.new("UIListLayout", Content)
Layout.Padding = UDim.new(0, 5)
Layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
Layout.SortOrder = Enum.SortOrder.LayoutOrder
local function makeBtn(text, color, order, fn)
local b = Instance.new("TextButton")
b.Size = UDim2.new(1, -4, 0, isMobile and 38 or 34)
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
l.Font = Enum.Font.SourceSansBold
l.TextSize = isMobile and 15 or 14
l.TextColor3 = Color3.fromRGB(255, 255, 255)
l.TextXAlignment = Enum.TextXAlignment.Center
b.MouseButton1Click:Connect(function() if fn then fn(b, l) end end)
return b, l
end
makeBtn("[ 自動貼人 ] OFF", C.bg3, 1, function(b, l)
Config.AutoStick = not Config.AutoStick
l.Text = "[ 自動貼人 ] " .. (Config.AutoStick and "ON" or "OFF")
local cor = Config.AutoStick and C.greenD or C.bg3
tw(b, {BackgroundColor3 = cor}, 0.25)
if not Config.AutoStick then CurrentStickTarget = nil end
end)
makeBtn("[ 自動普攻 ] OFF", C.bg3, 2, function(b, l)
Config.AutoAttack = not Config.AutoAttack
l.Text = "[ 自動普攻 ] " .. (Config.AutoAttack and "ON" or "OFF")
local cor = Config.AutoAttack and C.greenD or C.bg3
tw(b, {BackgroundColor3 = cor}, 0.25)
end)
local aimlockFloatBtn = Instance.new("TextButton", ScreenGui)
aimlockFloatBtn.Size = UDim2.new(0, 56, 0, 56)
aimlockFloatBtn.Position = UDim2.new(0.85, 0, 0.5, -28)
aimlockFloatBtn.BackgroundColor3 = Color3.fromRGB(28, 35, 45)
aimlockFloatBtn.BackgroundTransparency = 0.1
aimlockFloatBtn.BorderSizePixel = 0
aimlockFloatBtn.Text = "未鎖定"
aimlockFloatBtn.Font = Enum.Font.SourceSansBold
aimlockFloatBtn.TextSize = 14
aimlockFloatBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
aimlockFloatBtn.TextWrapped = true
aimlockFloatBtn.Visible = false
local aimlockFloatStroke = Instance.new("UIStroke", aimlockFloatBtn)
aimlockFloatStroke.Thickness = 2.0
aimlockFloatStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
local logoGrad = Instance.new("UIGradient", aimlockFloatStroke)
logoGrad.Color = ColorSequence.new({
ColorSequenceKeypoint.new(0, C.purpleBorder),
ColorSequenceKeypoint.new(0.5, Color3.fromRGB(200, 160, 255)),
ColorSequenceKeypoint.new(1, C.purpleBorder),
})
local baseRotationSpeed = 1.5
task.spawn(function()
while true do
RunService.RenderStepped:Wait()
local speed = IsLockingCamera and 3.5 or baseRotationSpeed
logoGrad.Rotation = (logoGrad.Rotation + speed) % 360
end
end)
makeBtn("[ 畫面強制鎖定 ] OFF", C.bg3, 3, function(b, l)
Config.AimlockEnabled = not Config.AimlockEnabled
l.Text = "[ 畫面強制鎖定 ] " .. (Config.AimlockEnabled and "ON" or "OFF")
local cor = Config.AimlockEnabled and C.greenD or C.bg3
tw(b, {BackgroundColor3 = cor}, 0.25)
aimlockFloatBtn.Visible = Config.AimlockEnabled
if not Config.AimlockEnabled then
IsLockingCamera = false; AimlockTargetChar = nil; LostTargetTime = 0
aimlockFloatBtn.Text = "未鎖定"
end
end)
makeBtn("[ 鎖定對象 ] NPC", C.greenD2, 4, function(b, l)
Config.TargetMode = (Config.TargetMode == "NPC") and "Player" or "NPC"
l.Text = "[ 鎖定對象 ] " .. (Config.TargetMode == "NPC" and "NPC" or "玩家")
AimlockTargetChar = nil; IsLockingCamera = false; LostTargetTime = 0; CurrentStickTarget = nil
aimlockFloatBtn.Text = "未鎖定"
end)
local Credit = Instance.new("TextLabel", Frame)
Credit.Size = UDim2.new(1, 0, 0, 24)
Credit.Position = UDim2.new(0, 0, 1, -26)
Credit.BackgroundColor3 = C.bg2
Credit.BackgroundTransparency = 0.5
Credit.BorderSizePixel = 0
Credit.Text = "格鬥腳本通用"
Credit.Font = Enum.Font.SourceSansBold
Credit.TextSize = 14
Credit.TextColor3 = C.textD
Credit.TextXAlignment = Enum.TextXAlignment.Center
Instance.new("UICorner", Credit).CornerRadius = UDim.new(0, 16)
local function setupLocalDrag(handleObj, targetObj)
local dragStart, startPos, dragging = nil, nil, false
handleObj.InputBegan:Connect(function(input)
if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
dragging = true
dragStart = input.Position
startPos = targetObj.Position
end
end)
UserInputService.InputChanged:Connect(function(input)
if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
local delta = input.Position - dragStart
targetObj.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
end
end)
UserInputService.InputEnded:Connect(function(input)
if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
end)
end
setupLocalDrag(TopBar, Frame)
setupLocalDrag(Ball, Ball)
local dragMoved = false
local draggingAim = false
local aimDragStart, aimStartPos
aimlockFloatBtn.InputBegan:Connect(function(input)
if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
draggingAim = true
dragMoved = false
aimDragStart = input.Position
aimStartPos = aimlockFloatBtn.Position
end
end)
UserInputService.InputChanged:Connect(function(input)
if draggingAim and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
local delta = input.Position - aimDragStart
if delta.Magnitude > 4 then dragMoved = true end
aimlockFloatBtn.Position = UDim2.new(aimStartPos.X.Scale, aimStartPos.X.Offset + delta.X, aimStartPos.Y.Scale, aimStartPos.Y.Offset + delta.Y)
end
end)
UserInputService.InputEnded:Connect(function(input)
if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then draggingAim = false end
end)
aimlockFloatBtn.MouseButton1Click:Connect(function()
if dragMoved or not Config.AimlockEnabled then return end
if IsLockingCamera then
IsLockingCamera = false
AimlockTargetChar = nil
LostTargetTime = 0
aimlockFloatBtn.Text = "未鎖定"
return
end
AimlockTargetChar = getFrontClosestTarget()
if AimlockTargetChar then
IsLockingCamera = true
LostTargetTime = 0
aimlockFloatBtn.Text = "鎖定"
else
aimlockFloatBtn.Text = "無目標"
task.wait(0.3)
aimlockFloatBtn.Text = "未鎖定"
end
end)
RunService.RenderStepped:Connect(function()
local myChar = LocalPlayer.Character
local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
if not myHrp then return end
local target = getStickTarget()
if Config.AutoStick and target then
local tHrp = target:FindFirstChild("HumanoidRootPart") or target:FindFirstChild("Torso")
if tHrp then
for _, part in ipairs(myChar:GetDescendants()) do if part:IsA("BasePart") then part.CanCollide = false end end
myHrp.CFrame = CFrame.lookAt(tHrp.Position - (tHrp.CFrame.LookVector * AttackDistance), tHrp.Position)
myHrp.AssemblyLinearVelocity = Vector3.zero
myHrp.AssemblyAngularVelocity = Vector3.zero
end
end
if Config.AimlockEnabled and IsLockingCamera and AimlockTargetChar and AimlockTargetChar.Parent then
local aimPart = AimlockTargetChar:FindFirstChild("Head") or AimlockTargetChar:FindFirstChild("HumanoidRootPart")
if aimPart and workspace.CurrentCamera then
workspace.CurrentCamera.CFrame = CFrame.lookAt(workspace.CurrentCamera.CFrame.Position, aimPart.Position)
end
end
end)
task.spawn(function()
while true do
task.wait(0.14)
if Config.AutoAttack and getStickTarget() then
VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 0)
task.wait(0.01)
VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0)
end
end
end)
aimlockFloatBtn.Visible = false
local minimized = false
MinBtn.MouseButton1Click:Connect(function() minimized = not minimized; Frame.Visible = not minimized end)
Ball.MouseButton1Click:Connect(function() minimized = not minimized; Frame.Visible = not minimized end)
task.spawn(function()
pcall(function()
game:GetService("StarterGui"):SetCore("SendNotification", {
Title = "腳本載入成功🟢",
Text = "", -- 副標題
Duration = 4
})
end)
end)
