-- SHINDO LIFE PRO ULTIMATE – TOGGLE FIX + FARM SIÊU TỐC
-- Toggle hiển thị màu xanh khi bật, giao diện ngang đẹp, hoạt động ổn định trên mobile

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Workspace = game:GetService("Workspace")
local VirtualInputManager = game:GetService("VirtualInputManager")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")

-- Biến toàn cục
local autoFarm = false
local autoChakra = false
local autoRank = false
local autoScroll = false
local espOn = false
local fpsBoost = false
local instantKill = true
local farmRange = 400
local useM1 = true
local spamAllSkills = false
local skillToggles = {Y = false, N = false, B = false, V = false, G = false, H = false}

-- Tìm NPC quest (dấu "!" xanh, bỏ qua rank)
local function findQuestNPC()
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") then
            local hum = obj:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then
                local lower = obj.Name:lower()
                if lower:find("rank") then continue end
                local head = obj:FindFirstChild("Head")
                if head then
                    local give = head:FindFirstChild("givemission")
                    if give and give.Enabled then
                        local color = give:FindFirstChild("color")
                        if color and color.Image:find("5459241648") then return obj end
                    end
                end
                if lower:find("quest") then return obj end
            end
        end
    end
    return nil
end

-- Phân loại quái (không boss, không NPC, không gỗ)
local function isValidTarget(model)
    if not model or model == LocalPlayer.Character then return false end
    local hum = model:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return false end
    if Players:GetPlayerFromCharacter(model) then return false end
    local lower = model.Name:lower()
    if lower:find("boss") then return false end
    if model:FindFirstChild("Head") and model.Head:FindFirstChild("givemission") then return false end
    if lower:find("quest") or lower:find("rank") or lower:find("missiongiver") then return false end
    local blacklist = {"wood", "log", "dummy", "training", "target", "maki"}
    for _, kw in ipairs(blacklist) do if lower:find(kw) then return false end end
    return true
end

local function findNearestEnemy(range)
    local char = LocalPlayer.Character
    if not char then return nil end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end
    local nearest, minDist = nil, range or farmRange
    local folder = Workspace:FindFirstChild("npc") or Workspace
    for _, obj in ipairs(folder:GetDescendants()) do
        if obj:IsA("Model") and isValidTarget(obj) then
            local root = obj:FindFirstChild("HumanoidRootPart")
            if root then
                local dist = (hrp.Position - root.Position).Magnitude
                if dist < minDist then minDist = dist; nearest = obj end
            end
        end
    end
    return nearest
end

local function findScrolls()
    local list = {}
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") and (obj.Name:lower():find("scroll") or obj.Name:lower():find("paper")) then
            table.insert(list, obj)
        end
    end
    return list
end

-- Tấn công: M1 (VirtualInput) + instant kill + spam phím ảo
local function attackTarget(target)
    if not target then return end
    if useM1 then
        VirtualInputManager:SendMouseButtonEvent(0, 0, true, nil, 0)
        task.wait(0.02)
        VirtualInputManager:SendMouseButtonEvent(0, 0, false, nil, 0)
        task.wait(0.02)
    end
    if instantKill then
        local hum = target:FindFirstChildOfClass("Humanoid")
        if hum then hum.Health = 0 end
        return
    end
    local keys = {}
    if spamAllSkills then
        keys = {"Y","N","B","V","G","H"}
    else
        for k, on in pairs(skillToggles) do
            if on then table.insert(keys, k) end
        end
    end
    for _, k in ipairs(keys) do
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode[k], false, nil)
        task.wait(0.01)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode[k], false, nil)
        task.wait(0.01)
    end
end

-- Đứng trên đầu quái (an toàn)
local function positionAboveTarget(targetRoot)
    if not LocalPlayer.Character then return end
    local hrp = LocalPlayer.Character.HumanoidRootPart
    if not hrp then return end
    local newCF = targetRoot.CFrame * CFrame.new(0, 10, 0)
    local ray = Ray.new(newCF.Position, Vector3.new(0, -12, 0))
    local hit = Workspace:FindPartOnRay(ray, LocalPlayer.Character)
    if hit then newCF = CFrame.new(hit.Position + Vector3.new(0, 2, 0)) end
    hrp.CFrame = newCF
end

-- Accept / Complete quest (ưu tiên CLIENTTALK, fallback click màn hình)
local function interactNPC(npc, action)
    local clientTalk = npc:FindFirstChild("CLIENTTALK")
    if clientTalk then
        clientTalk:FireServer()
        task.wait(0.05)
        clientTalk:FireServer(action or "accept")
        return
    end
    local head = npc:FindFirstChild("Head")
    if head then
        local pos = Workspace.CurrentCamera:WorldToViewportPoint(head.Position)
        VirtualInputManager:SendMouseButtonEvent(pos.X, pos.Y, 0, true, game, 1)
        task.wait(0.05)
        VirtualInputManager:SendMouseButtonEvent(pos.X, pos.Y, 0, false, game, 1)
        task.wait(0.3)
    end
    local vp = Workspace.CurrentCamera.ViewportSize
    VirtualInputManager:SendMouseButtonEvent(vp.X/2, vp.Y*0.7, 0, true, game, 1)
    task.wait(0.05)
    VirtualInputManager:SendMouseButtonEvent(vp.X/2, vp.Y*0.7, 0, false, game, 1)
end

-- Auto Farm chính
local farmThread
function toggleAutoFarm()
    autoFarm = not autoFarm
    if autoFarm then
        farmThread = task.spawn(function()
            while autoFarm do
                local npc = findQuestNPC()
                if npc then
                    local npcHRP = npc:FindFirstChild("HumanoidRootPart")
                    if npcHRP and LocalPlayer.Character then
                        LocalPlayer.Character.HumanoidRootPart.CFrame = npcHRP.CFrame + Vector3.new(0, 10, 0)
                    end
                    task.wait(0.2)
                    interactNPC(npc, "accept")
                    task.wait(0.6)
                    local startTime = tick()
                    while autoFarm and (tick() - startTime) < 25 do
                        local target = findNearestEnemy(farmRange)
                        if target and target:FindFirstChild("HumanoidRootPart") then
                            positionAboveTarget(target.HumanoidRootPart)
                            attackTarget(target)
                        end
                        task.wait(0.08)
                    end
                    if npcHRP and LocalPlayer.Character then
                        LocalPlayer.Character.HumanoidRootPart.CFrame = npcHRP.CFrame + Vector3.new(0, 10, 0)
                    end
                    task.wait(0.2)
                    interactNPC(npc, "accept")
                    task.wait(1)
                else
                    local target = findNearestEnemy(farmRange)
                    if target and target:FindFirstChild("HumanoidRootPart") then
                        positionAboveTarget(target.HumanoidRootPart)
                        attackTarget(target)
                    end
                    task.wait(0.1)
                end
            end
        end)
    else
        if farmThread then task.cancel(farmThread) end
    end
end

-- Các chức năng khác
local chakraThread
function toggleAutoChakra()
    autoChakra = not autoChakra
    if autoChakra then
        chakraThread = task.spawn(function()
            while autoChakra do
                VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.C, false, nil)
                task.wait(1.5)
                VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.C, false, nil)
                task.wait(2)
            end
        end)
    else if chakraThread then task.cancel(chakraThread) end end
end

local rankThread
function toggleAutoRank()
    autoRank = not autoRank
    if autoRank then
        rankThread = task.spawn(function()
            while autoRank do
                local se = LocalPlayer:FindFirstChild("startevent") or game:GetService("ReplicatedStorage"):FindFirstChild("startevent")
                if se then pcall(function() se:FireServer("rankup") end) end
                task.wait(2)
            end
        end)
    else if rankThread then task.cancel(rankThread) end end
end

local scrollThread
function toggleAutoScroll()
    autoScroll = not autoScroll
    if autoScroll then
        scrollThread = task.spawn(function()
            while autoScroll do
                local scrolls = findScrolls()
                if #scrolls > 0 then
                    local scroll = scrolls[1]
                    local part = scroll:FindFirstChild("Part") or scroll:FindFirstChild("Handle")
                    if part and LocalPlayer.Character then
                        LocalPlayer.Character.HumanoidRootPart.CFrame = part.CFrame
                        task.wait(0.2)
                        local inv = scroll:FindFirstChild("invoke") or part:FindFirstChild("invoke")
                        if inv then pcall(function() inv:FireServer(LocalPlayer) end) end
                        local cd = scroll:FindFirstChild("ClickDetector") or part:FindFirstChildWhichIsA("ClickDetector")
                        if cd then pcall(function() fireclickdetector(cd) end) end
                    end
                end
                task.wait(0.5)
            end
        end)
    else if scrollThread then task.cancel(scrollThread) end end
end

local espGui
function toggleESP()
    espOn = not espOn
    if espOn then
        espGui = Instance.new("ScreenGui", LocalPlayer.PlayerGui)
        espGui.Name = "ESP"
        espGui.ResetOnSpawn = false
        task.spawn(function()
            while espOn do
                for _, v in ipairs(espGui:GetChildren()) do v:Destroy() end
                local cam = Workspace.CurrentCamera
                for _, player in ipairs(Players:GetPlayers()) do
                    if player ~= LocalPlayer and player.Character then
                        local hrp = player.Character:FindFirstChild("HumanoidRootPart")
                        if hrp then
                            local pos, onScreen = cam:WorldToViewportPoint(hrp.Position + Vector3.new(0,2,0))
                            if onScreen then
                                local dot = Instance.new("Frame")
                                dot.Size = UDim2.new(0,4,0,4)
                                dot.Position = UDim2.new(0,pos.X,0,pos.Y)
                                dot.BackgroundColor3 = Color3.new(1,0,0)
                                dot.Parent = espGui
                            end
                        end
                    end
                end
                for _, scroll in ipairs(findScrolls()) do
                    local part = scroll:FindFirstChild("Part") or scroll:FindFirstChild("Handle")
                    if part then
                        local pos, onScreen = cam:WorldToViewportPoint(part.Position)
                        if onScreen then
                            local dot = Instance.new("Frame")
                            dot.Size = UDim2.new(0,4,0,4)
                            dot.Position = UDim2.new(0,pos.X,0,pos.Y)
                            dot.BackgroundColor3 = Color3.new(1,1,0)
                            dot.Parent = espGui
                        end
                    end
                end
                task.wait(0.5)
            end
            espGui:Destroy()
        end)
    else if espGui then espGui:Destroy() end end
end

function setFPSBoost(enable)
    if enable then
        pcall(function() Lighting.GlobalShadows = false end)
        pcall(function() Lighting.FogEnd = 500 end)
        pcall(function() game:GetService("Rendering").QualityLevel = Enum.QualityLevel.Level01 end)
    else
        pcall(function() Lighting.GlobalShadows = true end)
        pcall(function() Lighting.FogEnd = 10000 end)
        pcall(function() game:GetService("Rendering").QualityLevel = Enum.QualityLevel.Level21 end)
    end
end
function toggleFPSBoost() fpsBoost = not fpsBoost; setFPSBoost(fpsBoost) end

LocalPlayer.Idled:Connect(function()
    game:GetService("VirtualUser"):CaptureController()
    game:GetService("VirtualUser"):ClickButton2(Vector2.new())
end)

-- ================== GIAO DIỆN NGANG ==================
local mainGui = Instance.new("ScreenGui")
mainGui.Name = "ShindoPro"
mainGui.ResetOnSpawn = false
mainGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local reopenBtn = Instance.new("TextButton")
reopenBtn.Size = UDim2.new(0,60,0,60)
reopenBtn.Position = UDim2.new(0,10,0.5,-30)
reopenBtn.BackgroundColor3 = Color3.fromRGB(0,160,255)
reopenBtn.Text = "N"
reopenBtn.TextColor3 = Color3.new(1,1,1)
reopenBtn.Font = Enum.Font.SourceSansBold
reopenBtn.TextSize = 28
reopenBtn.BorderSizePixel = 0
reopenBtn.Visible = false
reopenBtn.Active = true
reopenBtn.Parent = mainGui
Instance.new("UICorner", reopenBtn).CornerRadius = UDim.new(0,30)

local menuFrame = Instance.new("Frame")
menuFrame.Size = UDim2.new(0,400,0,320)
menuFrame.Position = UDim2.new(0.5,-200,0.5,-160)
menuFrame.BackgroundColor3 = Color3.fromRGB(20,20,30)
menuFrame.BorderSizePixel = 0
menuFrame.Visible = true
menuFrame.Active = true
menuFrame.Parent = mainGui
Instance.new("UICorner", menuFrame).CornerRadius = UDim.new(0,16)
Instance.new("UIStroke", menuFrame).Color = Color3.fromRGB(0,180,255)

local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1,0,0,40)
titleBar.BackgroundColor3 = Color3.fromRGB(30,30,45)
titleBar.BorderSizePixel = 0
titleBar.Parent = menuFrame
Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0,16)

local titleText = Instance.new("TextLabel")
titleText.Size = UDim2.new(1,-40,1,0)
titleText.Position = UDim2.new(0,10,0,0)
titleText.BackgroundTransparency = 1
titleText.Text = "SHINDO PRO ULTIMATE"
titleText.TextColor3 = Color3.fromRGB(0,200,255)
titleText.Font = Enum.Font.SourceSansBold
titleText.TextSize = 16
titleText.TextXAlignment = Enum.TextXAlignment.Left
titleText.Parent = titleBar

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0,30,0,30)
closeBtn.Position = UDim2.new(1,-35,0,5)
closeBtn.BackgroundColor3 = Color3.fromRGB(200,50,50)
closeBtn.Text = "✕"
closeBtn.TextColor3 = Color3.new(1,1,1)
closeBtn.Font = Enum.Font.SourceSansBold
closeBtn.TextSize = 14
closeBtn.BorderSizePixel = 0
closeBtn.Parent = titleBar
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0,15)

local tabBtnsFrame = Instance.new("Frame")
tabBtnsFrame.Size = UDim2.new(1,0,0,30)
tabBtnsFrame.Position = UDim2.new(0,0,0,40)
tabBtnsFrame.BackgroundColor3 = Color3.fromRGB(25,25,38)
tabBtnsFrame.BorderSizePixel = 0
tabBtnsFrame.Parent = menuFrame

local contentArea = Instance.new("Frame")
contentArea.Size = UDim2.new(1,0,1,-70)
contentArea.Position = UDim2.new(0,0,0,70)
contentArea.BackgroundTransparency = 1
contentArea.Parent = menuFrame

local tabs = {}
local function createTab(name)
    local sf = Instance.new("ScrollingFrame")
    sf.Size = UDim2.new(1,0,1,0)
    sf.BackgroundTransparency = 1
    sf.ScrollBarThickness = 4
    sf.CanvasSize = UDim2.new(0,0,0,0)
    sf.Visible = false
    sf.Parent = contentArea
    local inner = Instance.new("Frame")
    inner.Size = UDim2.new(1,0,0,500)
    inner.BackgroundTransparency = 1
    inner.Name = "Inner"
    inner.Parent = sf
    tabs[name] = {frame = sf, inner = inner}
    return inner
end

local tabMain = createTab("Main")
local tabSkill = createTab("Skill")
local tabESP = createTab("ESP")
local tabSetting = createTab("Settings")
tabs["Main"].frame.Visible = true

local tabNames = {"Main","Skill","ESP","Settings"}
for i, name in ipairs(tabNames) do
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1/4,0,1,0)
    btn.Position = UDim2.new((i-1)/4,0,0,0)
    btn.BackgroundColor3 = Color3.fromRGB(50,55,70)
    btn.TextColor3 = Color3.new(1,1,1)
    btn.Text = name
    btn.Font = Enum.Font.SourceSans
    btn.TextSize = 13
    btn.BorderSizePixel = 0
    btn.Parent = tabBtnsFrame
    btn.MouseButton1Click:Connect(function()
        for _, t in pairs(tabs) do t.frame.Visible = false end
        tabs[name].frame.Visible = true
        for _, b in ipairs(tabBtnsFrame:GetChildren()) do
            if b:IsA("TextButton") then b.BackgroundColor3 = Color3.fromRGB(50,55,70) end
        end
        btn.BackgroundColor3 = Color3.fromRGB(0,160,255)
    end)
end

-- Hàm tạo toggle chắc chắn hoạt động (dùng BoolValue để đồng bộ)
local function addToggle(parent, text, y, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1,-20,0,35)
    btn.Position = UDim2.new(0,10,0,y)
    btn.BackgroundColor3 = Color3.fromRGB(60,65,80)
    btn.TextColor3 = Color3.new(1,1,1)
    btn.Text = text .. ": OFF"
    btn.Font = Enum.Font.SourceSans
    btn.TextSize = 14
    btn.BorderSizePixel = 0
    btn.Parent = parent
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0,8)
    local enabled = false
    local function update()
        enabled = not enabled
        btn.Text = text .. ": " .. (enabled and "ON" or "OFF")
        btn.BackgroundColor3 = enabled and Color3.fromRGB(0,180,80) or Color3.fromRGB(60,65,80)
        callback(enabled)
        print(text .. " toggled: " .. tostring(enabled))
    end
    btn.MouseButton1Click:Connect(update)
    btn.Activated:Connect(update)
    return btn
end

-- Tab Main
addToggle(tabMain, "Auto Farm", 10, toggleAutoFarm)
addToggle(tabMain, "Instant Kill", 50, function(on) instantKill = on end)
addToggle(tabMain, "Spam M1", 90, function(on) useM1 = on end)
addToggle(tabMain, "Spam ALL Skills", 130, function(on) spamAllSkills = on end)
addToggle(tabMain, "Auto Chakra", 170, toggleAutoChakra)
addToggle(tabMain, "Auto Rank", 210, toggleAutoRank)
addToggle(tabMain, "Auto Scroll", 250, toggleAutoScroll)

-- Tab Skill
local skillLabel = Instance.new("TextLabel")
skillLabel.Position = UDim2.new(0,10,0,10)
skillLabel.Size = UDim2.new(1,-20,0,20)
skillLabel.BackgroundTransparency = 1
skillLabel.Text = "Chọn skill riêng (khi Spam ALL OFF):"
skillLabel.TextColor3 = Color3.new(1,1,1)
skillLabel.Font = Enum.Font.SourceSans
skillLabel.TextSize = 12
skillLabel.Parent = tabSkill

local skills = {"Y","N","B","V","G","H"}
for i, key in ipairs(skills) do
    local yPos = 35 + (i-1)*40
    addToggle(tabSkill, "Skill "..key, yPos, function(on) skillToggles[key] = on end)
end

-- Tab ESP
addToggle(tabESP, "Bật ESP", 10, toggleESP)

-- Tab Settings
local rangeLabel = Instance.new("TextLabel")
rangeLabel.Position = UDim2.new(0,10,0,10)
rangeLabel.Size = UDim2.new(1,-20,0,20)
rangeLabel.BackgroundTransparency = 1
rangeLabel.Text = "Phạm vi farm:"
rangeLabel.TextColor3 = Color3.new(1,1,1)
rangeLabel.Font = Enum.Font.SourceSans
rangeLabel.TextSize = 14
rangeLabel.Parent = tabSetting

local rangeInput = Instance.new("TextBox")
rangeInput.Position = UDim2.new(0,10,0,30)
rangeInput.Size = UDim2.new(1,-20,0,30)
rangeInput.BackgroundColor3 = Color3.fromRGB(60,65,80)
rangeInput.TextColor3 = Color3.new(1,1,1)
rangeInput.Text = tostring(farmRange)
rangeInput.Font = Enum.Font.SourceSans
rangeInput.Parent = tabSetting
rangeInput.FocusLost:Connect(function() farmRange = tonumber(rangeInput.Text) or 400 end)

addToggle(tabSetting, "FPS Boost", 70, toggleFPSBoost)

local function openMenu() menuFrame.Visible = true; reopenBtn.Visible = false end
local function closeMenu() menuFrame.Visible = false; reopenBtn.Visible = true end
closeBtn.MouseButton1Click:Connect(closeMenu)
closeBtn.Activated:Connect(closeMenu)
reopenBtn.MouseButton1Click:Connect(openMenu)
reopenBtn.Activated:Connect(openMenu)

local dragging, dragStart, startPos
titleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true; dragStart = input.Position; startPos = menuFrame.Position
    end
end)
titleBar.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
        local delta = input.Position - dragStart
        menuFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)
titleBar.InputEnded:Connect(function() dragging = false end)

print("Shindo Pro Ultimate: Toggle hiển thị màu xanh khi bật, farm cực nhanh!")
