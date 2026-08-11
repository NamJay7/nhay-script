--[[
    SHINDO LIFE PRO – FULL FEATURES, STABLE
    - Menu ngang, tự động hiện, nút tắt X, nút mở lại "N" đen.
    - Auto Farm Level (tự nhận quest, đánh quái, tránh gỗ/player/boss).
    - Spam skill kết hợp M1, phạm vi xa, di chuyển thấp tránh bị đánh.
    - ESP (người chơi, scroll).
    - Auto Chakra (< 30%).
    - FPS Boost (giảm đồ họa).
    - Settings (skill, phạm vi).
]]

-- Dịch vụ
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInputManager = game:GetService("VirtualInputManager")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")

-- Tìm Remote
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

-- Biến toàn cục
local autoFarm = false
local autoChakra = false
local espOn = false
local fpsBoost = false
local farmRange = 250
local mainSkill = "Skill1"

-- Toggle riêng cho các skill phụ (Y,N,B,V)
local skillToggles = { Y = false, N = false, B = false, V = false }
local skillNames = { Y = "SkillY", N = "SkillN", B = "SkillB", V = "SkillV" }

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
            if gui:IsA("BillboardGui") and gui:FindFirstChild("TextLabel") and gui.TextLabel.Text == "!" then
                return false
            end
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
                local dist = (hrp.Position - root.Position).Magnitude
                if dist < minDist then minDist = dist; nearest = obj end
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
                            if (tl and tl.Text == "!") or (il and il.Image:find("exclamation")) then
                                return obj
                            end
                        end
                    end
                end
                if obj.Name:lower():find("quest") then return obj end
            end
        end
    end
    return nil
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

-- Tấn công (M1 + skill)
local function attackTarget(target, skill)
    if not target then return end
    skill = skill or mainSkill
    local root = target:FindFirstChild("HumanoidRootPart")
    if not root then return end
    -- M1
    if damageRemote then pcall(function() damageRemote:FireServer(target, "M1") end)
    else
        local pos, onScreen = Workspace.CurrentCamera:WorldToViewportPoint(root.Position)
        if onScreen then
            VirtualInputManager:SendMouseButtonEvent(pos.X, pos.Y, 0, true, game, 1)
            task.wait(0.05)
            VirtualInputManager:SendMouseButtonEvent(pos.X, pos.Y, 0, false, game, 1)
        end
    end
    task.wait(0.1)
    -- Skill
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

-- Hồi chakra
local function chargeChakra()
    if chakraRemote then pcall(function() chakraRemote:FireServer() end)
    else VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.C, false, game) task.wait(0.1) VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.C, false, game) end
end

local function getChakraPercent()
    local char = LocalPlayer.Character
    if not char then return 100 end
    local val = char:FindFirstChild("Chakra")
    if val and val:IsA("NumberValue") then
        local maxVal = char:FindFirstChild("MaxChakra") or char:FindFirstChild("MaxChakraValue")
        local max = (maxVal and maxVal:IsA("NumberValue") and maxVal.Value) or 100
        return (val.Value / max) * 100
    end
    return 100
end

-- FPS Boost
local function setFPSBoost(enable)
    if enable then
        pcall(function() Lighting.GlobalShadows = false end)
        pcall(function() Lighting.FogEnd = 500 end)
        pcall(function() game:GetService("Rendering").QualityLevel = Enum.QualityLevel.Level01 end)
        pcall(function() Workspace.StreamingMinRadius = 32 end)
        pcall(function() Workspace.StreamingTargetRadius = 64 end)
    else
        pcall(function() Lighting.GlobalShadows = true end)
        pcall(function() Lighting.FogEnd = 10000 end)
        pcall(function() game:GetService("Rendering").QualityLevel = Enum.QualityLevel.Level21 end)
        pcall(function() Workspace.StreamingMinRadius = 64 end)
        pcall(function() Workspace.StreamingTargetRadius = 256 end)
    end
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
                        VirtualInputManager:SendMouseButtonEvent(pos.X, pos.Y, 0, true, game, 1) task.wait(0.1) VirtualInputManager:SendMouseButtonEvent(pos.X, pos.Y, 0, false, game, 1)
                    end
                    task.wait(1.5)
                    local pg = LocalPlayer:FindFirstChild("PlayerGui")
                    local acceptBtn = pg and (pg:FindFirstChild("Accept") or pg:FindFirstChild("Yes"))
                    if acceptBtn and acceptBtn:IsA("TextButton") then
                        local btnPos = acceptBtn.AbsolutePosition + acceptBtn.AbsoluteSize/2
                        VirtualInputManager:SendMouseButtonEvent(btnPos.X, btnPos.Y, 0, true, game, 1) task.wait(0.1) VirtualInputManager:SendMouseButtonEvent(btnPos.X, btnPos.Y, 0, false, game, 1)
                    end
                    task.wait(1)
                    local startTime = tick()
                    while autoFarm and (tick() - startTime) < 20 do
                        local target = findNearestEnemy(farmRange)
                        if target then
                            -- Đứng dưới đất, thấp hơn mục tiêu để tránh bị đánh
                            TweenService:Create(LocalPlayer.Character.HumanoidRootPart, TweenInfo.new(0.2), {CFrame = target.HumanoidRootPart.CFrame * CFrame.new(0, -2, 0)}):Play()
                            attackTarget(target, mainSkill)
                            -- Spam thêm các skill được bật
                            for key, isOn in pairs(skillToggles) do
                                if isOn then attackTarget(target, skillNames[key]) end
                            end
                        end
                        task.wait(0.3)
                    end
                    if npcHRP then TweenService:Create(LocalPlayer.Character.HumanoidRootPart, TweenInfo.new(0.5), {CFrame = npcHRP.CFrame + Vector3.new(0,3,5)}):Play() end
                    task.wait(0.5)
                    if head then
                        local pos = Workspace.CurrentCamera:WorldToViewportPoint(head.Position)
                        VirtualInputManager:SendMouseButtonEvent(pos.X, pos.Y, 0, true, game, 1) task.wait(0.1) VirtualInputManager:SendMouseButtonEvent(pos.X, pos.Y, 0, false, game, 1)
                    end
                    task.wait(1.5)
                    local completeBtn = pg and (pg:FindFirstChild("Complete") or pg:FindFirstChild("Claim"))
                    if completeBtn and completeBtn:IsA("TextButton") then
                        local btnPos = completeBtn.AbsolutePosition + completeBtn.AbsoluteSize/2
                        VirtualInputManager:SendMouseButtonEvent(btnPos.X, btnPos.Y, 0, true, game, 1) task.wait(0.1) VirtualInputManager:SendMouseButtonEvent(btnPos.X, btnPos.Y, 0, false, game, 1)
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
                if getChakraPercent() < 30 then chargeChakra() end
                task.wait(1)
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

-- FPS Boost toggle
function toggleFPSBoost()
    fpsBoost = not fpsBoost
    setFPSBoost(fpsBoost)
end

-- === GIAO DIỆN NGANG ===
local mainGui = Instance.new("ScreenGui")
mainGui.Name = "ShindoPro"
mainGui.ResetOnSpawn = false
mainGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

-- Menu chính (ngang)
local menuFrame = Instance.new("Frame")
menuFrame.Size = UDim2.new(0, 400, 0, 250)
menuFrame.Position = UDim2.new(0.5, -200, 0.5, -125)
menuFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
menuFrame.BorderSizePixel = 0
menuFrame.Visible = true
menuFrame.Active = true
menuFrame.Parent = mainGui
Instance.new("UICorner", menuFrame).CornerRadius = UDim.new(0, 14)
Instance.new("UIStroke", menuFrame).Color = Color3.fromRGB(100,150,200)

-- Thanh tiêu đề
local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1,0,0,35)
titleBar.BackgroundColor3 = Color3.fromRGB(40,45,55)
titleBar.Parent = menuFrame

local titleText = Instance.new("TextLabel")
titleText.Size = UDim2.new(1,-40,1,0)
titleText.Position = UDim2.new(0,10,0,0)
titleText.BackgroundTransparency = 1
titleText.Text = "Shindo Pro"
titleText.TextColor3 = Color3.new(1,1,1)
titleText.Font = Enum.Font.SourceSansBold
titleText.TextSize = 16
titleText.TextXAlignment = Enum.TextXAlignment.Left
titleText.Parent = titleBar

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0,30,0,30)
closeBtn.Position = UDim2.new(1,-35,0,2)
closeBtn.BackgroundColor3 = Color3.fromRGB(200,60,60)
closeBtn.TextColor3 = Color3.new(1,1,1)
closeBtn.Font = Enum.Font.SourceSansBold
closeBtn.Text = "✕"
closeBtn.TextSize = 16
closeBtn.BorderSizePixel = 0
closeBtn.Parent = titleBar
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0,8)

-- Tabs (ngang)
local tabContainer = Instance.new("Frame")
tabContainer.Size = UDim2.new(1,0,1,-35)
tabContainer.Position = UDim2.new(0,0,0,35)
tabContainer.BackgroundTransparency = 1
tabContainer.Parent = menuFrame

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
local tabSet = addTab("Settings")
tabs["Main"].Visible = true

-- Nút tab (ngang bên trái titleBar) – đặt bên trong titleBar?
-- Do menu ngang nhỏ, ta đặt tab buttons ngay dưới titleBar, cao 25px
local tabButtonsFrame = Instance.new("Frame")
tabButtonsFrame.Size = UDim2.new(1,0,0,25)
tabButtonsFrame.Position = UDim2.new(0,0,0,35)
tabButtonsFrame.BackgroundColor3 = Color3.fromRGB(30,30,35)
tabButtonsFrame.BorderSizePixel = 0
tabButtonsFrame.Parent = menuFrame

local tabNames = {"Main", "ESP", "Settings"}
for i, name in ipairs(tabNames) do
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1/3, 0, 1, 0)
    btn.Position = UDim2.new((i-1)/3, 0, 0, 0)
    btn.BackgroundColor3 = Color3.fromRGB(50,55,65)
    btn.TextColor3 = Color3.new(1,1,1)
    btn.Text = name
    btn.Font = Enum.Font.SourceSans
    btn.TextSize = 14
    btn.BorderSizePixel = 0
    btn.Parent = tabButtonsFrame
    btn.MouseButton1Click:Connect(function()
        for _, t in pairs(tabs) do t.Visible = false end
        tabs[name].Visible = true
    end)
end

-- Vùng nội dung tab (phần còn lại của menuFrame bên dưới tabButtons)
local contentArea = Instance.new("Frame")
contentArea.Size = UDim2.new(1,0,1,-65) -- 35 title + 25 tab = 60
contentArea.Position = UDim2.new(0,0,0,65)
contentArea.BackgroundTransparency = 1
contentArea.Parent = menuFrame

-- Di chuyển các tab frame vào contentArea
for name, t in pairs(tabs) do
    t.Parent = contentArea
end

-- Hàm tạo toggle trong tab
local function addToggle(tab, text, y, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -20, 0, 30)
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
end

-- Tab Main
addToggle(tabMain, "Auto Farm", 10, toggleAutoFarm)
addToggle(tabMain, "Auto Chakra", 45, toggleAutoChakra)

-- Tab ESP
addToggle(tabESP, "Bật ESP", 10, toggleESP)

-- Tab Settings
local skillLabel = Instance.new("TextLabel")
skillLabel.Position = UDim2.new(0,10,0,10)
skillLabel.Size = UDim2.new(1,-20,0,20)
skillLabel.BackgroundTransparency = 1
skillLabel.Text = "Skill Chính:"
skillLabel.TextColor3 = Color3.new(1,1,1)
skillLabel.Font = Enum.Font.SourceSans
skillLabel.Parent = tabSet

local skillInput = Instance.new("TextBox")
skillInput.Position = UDim2.new(0,10,0,30)
skillInput.Size = UDim2.new(1,-20,0,25)
skillInput.BackgroundColor3 = Color3.fromRGB(100,149,237)
skillInput.TextColor3 = Color3.new(1,1,1)
skillInput.Text = mainSkill
skillInput.Font = Enum.Font.SourceSans
skillInput.Parent = tabSet
skillInput.FocusLost:Connect(function()
    mainSkill = skillInput.Text ~= "" and skillInput.Text or "Skill1"
end)

local rangeLabel = Instance.new("TextLabel")
rangeLabel.Position = UDim2.new(0,10,0,65)
rangeLabel.Size = UDim2.new(1,-20,0,20)
rangeLabel.BackgroundTransparency = 1
rangeLabel.Text = "Phạm vi:"
rangeLabel.TextColor3 = Color3.new(1,1,1)
rangeLabel.Font = Enum.Font.SourceSans
rangeLabel.Parent = tabSet

local rangeInput = Instance.new("TextBox")
rangeInput.Position = UDim2.new(0,10,0,85)
rangeInput.Size = UDim2.new(1,-20,0,25)
rangeInput.BackgroundColor3 = Color3.fromRGB(100,149,237)
rangeInput.TextColor3 = Color3.new(1,1,1)
rangeInput.Text = tostring(farmRange)
rangeInput.Font = Enum.Font.SourceSans
rangeInput.Parent = tabSet
rangeInput.FocusLost:Connect(function()
    farmRange = tonumber(rangeInput.Text) or 250
end)

addToggle(tabSet, "FPS Boost", 120, toggleFPSBoost)

-- Toggle skill phụ (Y,N,B,V) – đặt trong tab Main hoặc tab Settings? Để trong tab Settings cho gọn.
local skillToggleY = 155
for i, key in ipairs({"Y","N","B","V"}) do
    local label = Instance.new("TextLabel")
    label.Position = UDim2.new(0,10,0,skillToggleY + (i-1)*30)
    label.Size = UDim2.new(0,20,0,20)
    label.BackgroundTransparency = 1
    label.Text = key
    label.TextColor3 = Color3.new(1,1,1)
    label.Font = Enum.Font.SourceSansBold
    label.Parent = tabSet

    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Size = UDim2.new(0,40,0,20)
    toggleBtn.Position = UDim2.new(0,35,0,skillToggleY + (i-1)*30)
    toggleBtn.BackgroundColor3 = Color3.fromRGB(100,149,237)
    toggleBtn.TextColor3 = Color3.new(1,1,1)
    toggleBtn.Text = "OFF"
    toggleBtn.Font = Enum.Font.SourceSans
    toggleBtn.TextSize = 12
    toggleBtn.BorderSizePixel = 0
    toggleBtn.Parent = tabSet
    Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0,4)

    local input = Instance.new("TextBox")
    input.Size = UDim2.new(1,-85,0,20)
    input.Position = UDim2.new(0,80,0,skillToggleY + (i-1)*30)
    input.BackgroundColor3 = Color3.fromRGB(100,149,237)
    input.TextColor3 = Color3.new(1,1,1)
    input.Text = skillNames[key]
    input.Font = Enum.Font.SourceSans
    input.TextSize = 12
    input.Parent = tabSet
    input.FocusLost:Connect(function()
        skillNames[key] = input.Text ~= "" and input.Text or skillNames[key]
    end)

    local enabled = false
    toggleBtn.MouseButton1Click:Connect(function()
        enabled = not enabled
        toggleBtn.Text = enabled and "ON" or "OFF"
        toggleBtn.BackgroundColor3 = enabled and Color3.fromRGB(34,139,34) or Color3.fromRGB(100,149,237)
        skillToggles[key] = enabled
    end)
end

-- Nút mở lại (N đen)
local reopenBtn = Instance.new("TextButton")
reopenBtn.Size = UDim2.new(0,50,0,50)
reopenBtn.Position = UDim2.new(0,10,0.5,-25)
reopenBtn.BackgroundColor3 = Color3.fromRGB(0,140,200)
reopenBtn.TextColor3 = Color3.new(0,0,0)
reopenBtn.Font = Enum.Font.SourceSansBold
reopenBtn.Text = "N"
reopenBtn.TextSize = 30
reopenBtn.BorderSizePixel = 0
reopenBtn.Visible = false
reopenBtn.Active = true
reopenBtn.Parent = mainGui
Instance.new("UICorner", reopenBtn).CornerRadius = UDim.new(0,25)

-- Hàm đóng/mở menu
local function closeMenu()
    menuFrame.Visible = false
    reopenBtn.Visible = true
end
local function openMenu()
    menuFrame.Visible = true
    reopenBtn.Visible = false
end

closeBtn.MouseButton1Click:Connect(closeMenu)
closeBtn.Activated:Connect(closeMenu)
reopenBtn.MouseButton1Click:Connect(openMenu)
reopenBtn.Activated:Connect(openMenu)

-- Kéo thả
local dragging, dragStart, startPos
titleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = menuFrame.Position
        input.UserInputState = Enum.UserInputState.Began
    end
end)
titleBar.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
        local delta = input.Position - dragStart
        menuFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)
titleBar.InputEnded:Connect(function() dragging = false end)

-- FPS Boost mặc định tắt
setFPSBoost(false)

print("Shindo Pro Full Loaded! Menu ngang, tính năng đầy đủ.")
