--[[
    SHINDO LIFE PRO MOBILE – MENU ĐÃ HOẠT ĐỘNG
    - Nút "+" chạm để mở menu.
    - Menu kéo thả qua thanh tiêu đề.
    - Auto Farm, Auto Chakra, ESP, v.v.
]]

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInputManager = game:GetService("VirtualInputManager")
local TweenService = game:GetService("TweenService")

-- Remote
local function findRemote(name)
    for _, v in ipairs(ReplicatedStorage:GetDescendants()) do
        if v:IsA("RemoteEvent") and v.Name == name then return v end
    end
    local remFolder = ReplicatedStorage:FindFirstChild("Remotes")
    if remFolder then
        for _, v in ipairs(remFolder:GetDescendants()) do
            if v:IsA("RemoteEvent") and v.Name == name then return v end
        end
    end
    return nil
end

local damageRemote = findRemote("Damage") or findRemote("CastSpell") or findRemote("Attack")
local chakraRemote = findRemote("ChargeChakra") or findRemote("RechargeChakra")

-- Biến
local autoFarm = false
local autoChakra = false
local espOn = false
local farmRange = 250
local mainSkill = "Skill1"

-- Hàm kiểm tra mục tiêu hợp lệ
local function isValidTarget(model)
    if not model or model == LocalPlayer.Character then return false end
    local hum = model:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return false end
    if Players:GetPlayerFromCharacter(model) then return false end
    local lower = model.Name:lower()
    if lower:find("boss") then return false end
    local blacklist = {"wood", "log", "dummy", "training", "target", "maki"}
    for _, kw in ipairs(blacklist) do if lower:find(kw) then return false end end
    local head = model:FindFirstChild("Head")
    if head then
        for _, gui in ipairs(head:GetChildren()) do
            if gui:IsA("BillboardGui") and gui:FindFirstChild("TextLabel") and gui.TextLabel.Text == "!" then return false end
        end
    end
    return true
end

local function findNearestEnemy(range)
    local char = LocalPlayer.Character
    if not char then return nil end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end
    local nearest, minDist = nil, range or 250
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") and isValidTarget(obj) then
            local root = obj:FindFirstChild("HumanoidRootPart")
            if root then
                local d = (hrp.Position - root.Position).Magnitude
                if d < minDist then minDist = d; nearest = obj end
            end
        end
    end
    return nearest
end

local function findQuestNPC()
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") then
            local hum = obj:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then
                local head = obj:FindFirstChild("Head")
                if head then
                    for _, gui in ipairs(head:GetChildren()) do
                        if gui:IsA("BillboardGui") then
                            local tl = gui:FindFirstChild("TextLabel")
                            local il = gui:FindFirstChild("ImageLabel")
                            if (tl and tl.Text == "!") or (il and il.Image:find("exclamation")) then return obj end
                        end
                    end
                end
                if obj.Name:lower():find("quest") then return obj end
            end
        end
    end
    return nil
end

local function findScrolls() -- trả về list
    local list = {}
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") and (obj.Name:lower():find("scroll") or obj.Name:lower():find("paper")) then
            table.insert(list, obj)
        end
    end
    return list
end

local function attackTarget(target, skill)
    if not target then return end
    skill = skill or mainSkill
    local root = target:FindFirstChild("HumanoidRootPart")
    if not root then return end
    if damageRemote then pcall(function() damageRemote:FireServer(target, skill) end)
    else
        local pos, onScreen = Workspace.CurrentCamera:WorldToViewportPoint(root.Position)
        if onScreen then
            VirtualInputManager:SendMouseButtonEvent(pos.X, pos.Y, 0, true, game, 1)
            task.wait(0.05)
            VirtualInputManager:SendMouseButtonEvent(pos.X, pos.Y, 0, false, game, 1)
        end
    end
end

local function chargeChakra()
    if chakraRemote then pcall(function() chakraRemote:FireServer() end)
    else VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.C, false, game) task.wait(0.1) VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.C, false, game) end
end

-- Auto Farm
local farmThread
function toggleAutoFarm()
    autoFarm = not autoFarm
    if autoFarm then
        farmThread = task.spawn(function()
            while autoFarm do
                local npc = findQuestNPC()
                if npc then
                    local npcHRP = npc:FindFirstChild("HumanoidRootPart")
                    if npcHRP then TweenService:Create(LocalPlayer.Character.HumanoidRootPart, TweenInfo.new(0.5), {CFrame = npcHRP.CFrame + Vector3.new(0,3,5)}):Play() end
                    task.wait(0.5)
                    local head = npc:FindFirstChild("Head")
                    if head then
                        local pos = Workspace.CurrentCamera:WorldToViewportPoint(head.Position)
                        VirtualInputManager:SendMouseButtonEvent(pos.X, pos.Y, 0, true, game, 1)
                        task.wait(0.1)
                        VirtualInputManager:SendMouseButtonEvent(pos.X, pos.Y, 0, false, game, 1)
                    end
                    task.wait(1.5)
                    local pg = LocalPlayer:FindFirstChild("PlayerGui")
                    local acceptBtn = pg and (pg:FindFirstChild("Accept") or pg:FindFirstChild("Yes"))
                    if acceptBtn and acceptBtn:IsA("TextButton") then
                        local btnPos = acceptBtn.AbsolutePosition + acceptBtn.AbsoluteSize/2
                        VirtualInputManager:SendMouseButtonEvent(btnPos.X, btnPos.Y, 0, true, game, 1)
                        task.wait(0.1)
                        VirtualInputManager:SendMouseButtonEvent(btnPos.X, btnPos.Y, 0, false, game, 1)
                    end
                    task.wait(1)
                    local startTime = tick()
                    while autoFarm and (tick() - startTime) < 20 do
                        local target = findNearestEnemy(farmRange)
                        if target then
                            TweenService:Create(LocalPlayer.Character.HumanoidRootPart, TweenInfo.new(0.2), {CFrame = target.HumanoidRootPart.CFrame * CFrame.new(0, -2, 0)}):Play()
                            attackTarget(target, mainSkill)
                        end
                        task.wait(0.3)
                    end
                    if npcHRP then TweenService:Create(LocalPlayer.Character.HumanoidRootPart, TweenInfo.new(0.5), {CFrame = npcHRP.CFrame + Vector3.new(0,3,5)}):Play() end
                    task.wait(0.5)
                    if head then
                        local pos = Workspace.CurrentCamera:WorldToViewportPoint(head.Position)
                        VirtualInputManager:SendMouseButtonEvent(pos.X, pos.Y, 0, true, game, 1)
                        task.wait(0.1)
                        VirtualInputManager:SendMouseButtonEvent(pos.X, pos.Y, 0, false, game, 1)
                    end
                    task.wait(1.5)
                    local completeBtn = pg and (pg:FindFirstChild("Complete") or pg:FindFirstChild("Claim"))
                    if completeBtn and completeBtn:IsA("TextButton") then
                        local btnPos = completeBtn.AbsolutePosition + completeBtn.AbsoluteSize/2
                        VirtualInputManager:SendMouseButtonEvent(btnPos.X, btnPos.Y, 0, true, game, 1)
                        task.wait(0.1)
                        VirtualInputManager:SendMouseButtonEvent(btnPos.X, btnPos.Y, 0, false, game, 1)
                    end
                    task.wait(2)
                else
                    task.wait(2)
                end
            end
        end)
    else
        if farmThread then task.cancel(farmThread) end
    end
end

-- Auto Chakra
local chakraThread
function toggleAutoChakra()
    autoChakra = not autoChakra
    if autoChakra then
        chakraThread = task.spawn(function()
            while autoChakra do
                -- Giả định chakra < 30%
                chargeChakra()
                task.wait(3)
            end
        end)
    else if chakraThread then task.cancel(chakraThread) end end
end

-- ESP
local espGui
function toggleESP()
    espOn = not espOn
    if espOn then
        espGui = Instance.new("ScreenGui")
        espGui.Name = "ESP"
        espGui.ResetOnSpawn = false
        espGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
        task.spawn(function()
            while espOn do
                -- Xóa cũ
                for _, v in ipairs(espGui:GetChildren()) do v:Destroy() end
                local cam = Workspace.CurrentCamera
                -- Người chơi
                for _, player in ipairs(Players:GetPlayers()) do
                    if player ~= LocalPlayer and player.Character then
                        local hrp = player.Character:FindFirstChild("HumanoidRootPart")
                        if hrp then
                            local pos, onScreen = cam:WorldToViewportPoint(hrp.Position + Vector3.new(0,2,0))
                            if onScreen then
                                local dot = Instance.new("Frame")
                                dot.Size = UDim2.new(0, 4, 0, 4)
                                dot.Position = UDim2.new(0, pos.X, 0, pos.Y)
                                dot.BackgroundColor3 = Color3.new(1,0,0)
                                dot.Parent = espGui
                            end
                        end
                    end
                end
                -- Scroll
                for _, scroll in ipairs(findScrolls()) do
                    local part = scroll:FindFirstChild("Part") or scroll:FindFirstChild("Handle")
                    if part then
                        local pos, onScreen = cam:WorldToViewportPoint(part.Position)
                        if onScreen then
                            local dot = Instance.new("Frame")
                            dot.Size = UDim2.new(0, 4, 0, 4)
                            dot.Position = UDim2.new(0, pos.X, 0, pos.Y)
                            dot.BackgroundColor3 = Color3.new(1,1,0)
                            dot.Parent = espGui
                        end
                    end
                end
                task.wait(0.5)
            end
            espGui:Destroy()
        end)
    else
        if espGui then espGui:Destroy() end
    end
end

-- Giao diện
local mainGui = Instance.new("ScreenGui")
mainGui.Name = "ShindoPro"
mainGui.ResetOnSpawn = false
mainGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

-- Nút toggle menu – dùng InputBegan
local toggleBtn = Instance.new("TextButton")
toggleBtn.Size = UDim2.new(0, 60, 0, 60)
toggleBtn.Position = UDim2.new(0, 10, 0.5, -30)
toggleBtn.BackgroundColor3 = Color3.fromRGB(135,206,235)
toggleBtn.Text = "+"
toggleBtn.TextColor3 = Color3.new(1,1,1)
toggleBtn.Font = Enum.Font.SourceSansBold
toggleBtn.TextSize = 36
toggleBtn.BackgroundTransparency = 0.2
toggleBtn.BorderSizePixel = 0
toggleBtn.ZIndex = 200
toggleBtn.Active = true
toggleBtn.AutoButtonColor = false
toggleBtn.Parent = mainGui
Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0,12)

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 300, 0, 400)
mainFrame.Position = UDim2.new(0, 100, 0.5, -200)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
mainFrame.BorderSizePixel = 0
mainFrame.Visible = false
mainFrame.Parent = mainGui
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0,12)

local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1,0,0,35)
titleBar.BackgroundColor3 = Color3.fromRGB(70,130,180)
titleBar.BorderSizePixel = 0
titleBar.Parent = mainFrame

local titleText = Instance.new("TextLabel")
titleText.Size = UDim2.new(1,0,1,0)
titleText.BackgroundTransparency = 1
titleText.Text = "Shindo Pro"
titleText.TextColor3 = Color3.new(1,1,1)
titleText.Font = Enum.Font.SourceSansBold
titleText.TextSize = 16
titleText.Parent = titleBar

-- Tab system
local tabContainer = Instance.new("Frame")
tabContainer.Size = UDim2.new(1,0,1,-35)
tabContainer.Position = UDim2.new(0,0,0,35)
tabContainer.BackgroundTransparency = 1
tabContainer.Parent = mainFrame

local tabs = {}
local function addTab(name)
    local t = Instance.new("Frame")
    t.Size = UDim2.new(1,0,1,0)
    t.BackgroundTransparency = 1
    t.Visible = false
    t.Parent = tabContainer
    tabs[name] = t
    return t
end
local tabMain = addTab("Main")
local tabESP = addTab("ESP")
local tabSet = addTab("Set")
tabs["Main"].Visible = true

-- Tab buttons
local tabNames = {"Main", "ESP", "Set"}
for i, name in ipairs(tabNames) do
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1/3, 0, 0, 25)
    btn.Position = UDim2.new((i-1)/3, 0, 0, 0)
    btn.BackgroundColor3 = Color3.fromRGB(70,130,180)
    btn.TextColor3 = Color3.new(1,1,1)
    btn.Text = name
    btn.Font = Enum.Font.SourceSans
    btn.TextSize = 14
    btn.Parent = titleBar
    btn.MouseButton1Click:Connect(function()
        for _, t in pairs(tabs) do t.Visible = false end
        tabs[name].Visible = true
    end)
end

-- Toggle function
local function addToggle(tab, text, y, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -20, 0, 35)
    btn.Position = UDim2.new(0, 10, 0, y)
    btn.BackgroundColor3 = Color3.fromRGB(100,149,237)
    btn.TextColor3 = Color3.new(1,1,1)
    btn.Font = Enum.Font.SourceSans
    btn.Text = text .. ": OFF"
    btn.TextSize = 14
    btn.BorderSizePixel = 0
    btn.Parent = tab
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0,6)
    local enabled = false
    btn.MouseButton1Click:Connect(function()
        enabled = not enabled
        btn.Text = text .. ": " .. (enabled and "ON" or "OFF")
        btn.BackgroundColor3 = enabled and Color3.fromRGB(34,139,34) or Color3.fromRGB(100,149,237)
        callback(enabled)
    end)
    return btn
end

-- Populate tabs
addToggle(tabMain, "Auto Farm", 10, function(on) toggleAutoFarm() end)
addToggle(tabMain, "Auto Chakra", 50, function(on) toggleAutoChakra() end)
addToggle(tabESP, "Bật ESP", 10, function(on) toggleESP() end)

-- Settings
local skillLabel = Instance.new("TextLabel")
skillLabel.Position = UDim2.new(0,10,0,10)
skillLabel.Size = UDim2.new(1,-20,0,25)
skillLabel.BackgroundTransparency = 1
skillLabel.Text = "Skill Chính:"
skillLabel.TextColor3 = Color3.new(1,1,1)
skillLabel.Font = Enum.Font.SourceSans
skillLabel.Parent = tabSet

local skillInput = Instance.new("TextBox")
skillInput.Position = UDim2.new(0,10,0,35)
skillInput.Size = UDim2.new(1,-20,0,30)
skillInput.BackgroundColor3 = Color3.fromRGB(100,149,237)
skillInput.TextColor3 = Color3.new(1,1,1)
skillInput.Text = mainSkill
skillInput.Font = Enum.Font.SourceSans
skillInput.Parent = tabSet
skillInput.FocusLost:Connect(function()
    mainSkill = skillInput.Text ~= "" and skillInput.Text or "Skill1"
end)

local rangeLabel = Instance.new("TextLabel")
rangeLabel.Position = UDim2.new(0,10,0,75)
rangeLabel.Size = UDim2.new(1,-20,0,25)
rangeLabel.BackgroundTransparency = 1
rangeLabel.Text = "Phạm vi:"
rangeLabel.TextColor3 = Color3.new(1,1,1)
rangeLabel.Font = Enum.Font.SourceSans
rangeLabel.Parent = tabSet

local rangeInput = Instance.new("TextBox")
rangeInput.Position = UDim2.new(0,10,0,100)
rangeInput.Size = UDim2.new(1,-20,0,30)
rangeInput.BackgroundColor3 = Color3.fromRGB(100,149,237)
rangeInput.TextColor3 = Color3.new(1,1,1)
rangeInput.Text = tostring(farmRange)
rangeInput.Font = Enum.Font.SourceSans
rangeInput.Parent = tabSet
rangeInput.FocusLost:Connect(function()
    farmRange = tonumber(rangeInput.Text) or 250
end)

-- Kéo thả menu
local dragging, startDrag, startMenuPos
titleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        startDrag = input.Position
        startMenuPos = mainFrame.Position
        input.UserInputState = Enum.UserInputState.Began
    end
end)
titleBar.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
        local delta = input.Position - startDrag
        mainFrame.Position = UDim2.new(startMenuPos.X.Scale, startMenuPos.X.Offset + delta.X, startMenuPos.Y.Scale, startMenuPos.Y.Offset + delta.Y)
    end
end)
titleBar.InputEnded:Connect(function() dragging = false end)

-- Toggle menu: sử dụng InputBegan cho nút "+"
local menuVisible = false
toggleBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        menuVisible = not menuVisible
        mainFrame.Visible = menuVisible
        toggleBtn.Text = menuVisible and "−" or "+"
    end
end)

print("Shindo Pro ready: Tap '+' to open menu.")
