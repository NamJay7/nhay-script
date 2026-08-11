--[[
    SHINDO LIFE PRO MOBILE FINAL – ĐẦY ĐỦ, ỔN ĐỊNH
    - Giao diện kéo thả tự do.
    - Auto Farm Level: tự nhận quest, đánh quái quest (tránh gỗ, boss, player), kết hợp M1 và skill.
    - Auto Chakra: hồi khi dưới 30%.
    - Spam Skill: bàn phím ảo Y,N,B,V dạng toggle (bật/tắt tự động spam skill đó).
    - Auto Scroll: nhặt scroll.
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

-- Remote
local function findRemote(name)
    for _,v in ipairs(ReplicatedStorage:GetDescendants()) do
        if v:IsA("RemoteEvent") and v.Name == name then return v end
    end
    local rem = ReplicatedStorage:FindFirstChild("Remotes")
    if rem then for _,v in ipairs(rem:GetDescendants()) do if v:IsA("RemoteEvent") and v.Name == name then return v end end end
    return nil
end

local damageRemote = findRemote("Damage") or findRemote("CastSpell") or findRemote("Attack")
local questAcceptRemote = findRemote("AcceptQuest") or findRemote("StartQuest")
local questCompleteRemote = findRemote("CompleteQuest") or findRemote("FinishQuest")
local rankUpRemote = findRemote("RankUp") or findRemote("Promote")
local chakraRemote = findRemote("ChargeChakra") or findRemote("RechargeChakra")

-- Biến
local autoFarm = false
local autoChakra = false
local autoScroll = false
local farmRange = 200
local spamSkillName = "Skill1"  -- mặc định
local m1Enabled = true  -- spam M1 cùng lúc

-- Skill toggles cho các nút ảo
local skillToggles = {
    Y = false,
    N = false,
    B = false,
    V = false
}
-- Tên skill tương ứng (cấu hình được)
local skillNames = {
    Y = "SkillY",
    N = "SkillN",
    B = "SkillB",
    V = "SkillV"
}

-- Hàm kiểm tra quái hợp lệ (không phải gỗ, không phải boss, không phải player)
local function isValidTarget(model)
    if not model or model == LocalPlayer.Character then return false end
    local hum = model:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return false end
    -- Bỏ qua player
    if Players:GetPlayerFromCharacter(model) then return false end
    -- Bỏ qua boss (nếu tên chứa "boss")
    if model.Name:lower():find("boss") then return false end
    -- Bỏ qua gỗ, bù nhìn
    local blacklist = {"wood", "log", "dummy", "training", "target", "maki"}
    local lowerName = model.Name:lower()
    for _, kw in ipairs(blacklist) do
        if lowerName:find(kw) then return false end
    end
    -- Nếu là NPC quest (có dấu !) thì bỏ qua
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

local function findNearestValidEnemy(range)
    local char = LocalPlayer.Character
    if not char then return nil end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end
    local nearest, minDist = nil, range or 200
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") and isValidTarget(obj) then
            local root = obj:FindFirstChild("HumanoidRootPart")
            if root then
                local dist = (hrp.Position - root.Position).Magnitude
                if dist < minDist then
                    minDist = dist
                    nearest = obj
                end
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
            end
        end
    end
    return nil
end

local function findScroll()
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") and (obj.Name:lower():find("scroll") or obj.Name:lower():find("paper")) then
            return obj
        end
    end
    return nil
end

-- Hàm tấn công
local function attack(target, skillName)
    if not target then return end
    skillName = skillName or spamSkillName
    if m1Enabled then  -- kết hợp M1
        if damageRemote then
            pcall(function() damageRemote:FireServer(target, "M1") end)
        else
            local root = target:FindFirstChild("HumanoidRootPart")
            if root then
                local pos, onScreen = Workspace.CurrentCamera:WorldToViewportPoint(root.Position)
                if onScreen then
                    VirtualInputManager:SendMouseButtonEvent(pos.X, pos.Y, 0, true, game, 1)
                    task.wait(0.05)
                    VirtualInputManager:SendMouseButtonEvent(pos.X, pos.Y, 0, false, game, 1)
                end
            end
        end
        task.wait(0.1)
    end
    if damageRemote then
        pcall(function() damageRemote:FireServer(target, skillName) end)
    else
        local root = target:FindFirstChild("HumanoidRootPart")
        if root then
            local pos, onScreen = Workspace.CurrentCamera:WorldToViewportPoint(root.Position)
            if onScreen then
                VirtualInputManager:SendMouseButtonEvent(pos.X, pos.Y, 0, true, game, 1)
                task.wait(0.05)
                VirtualInputManager:SendMouseButtonEvent(pos.X, pos.Y, 0, false, game, 1)
            end
        end
    end
end

local function chargeChakra()
    if chakraRemote then
        pcall(function() chakraRemote:FireServer() end)
    else
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.C, false, game)
        task.wait(0.1)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.C, false, game)
    end
end

-- Đọc chakra (giả định tồn tại NumberValue "Chakra" trong Character)
local function getChakraPercent()
    local char = LocalPlayer.Character
    if not char then return 100 end
    local chakraValue = char:FindFirstChild("Chakra")  -- có thể là NumberValue
    if chakraValue and chakraValue:IsA("NumberValue") then
        local maxChakra = 100  -- mặc định
        local maxVal = char:FindFirstChild("MaxChakra") or char:FindFirstChild("MaxChakraValue")
        if maxVal and maxVal:IsA("NumberValue") then maxChakra = maxVal.Value end
        return (chakraValue.Value / maxChakra) * 100
    end
    return 100
end

-- Auto Farm (tự nhận quest -> farm)
local farmThread
function toggleAutoFarm()
    autoFarm = not autoFarm
    if autoFarm then
        farmThread = task.spawn(function()
            while autoFarm do
                -- Tìm NPC quest
                local npc = findQuestNPC()
                if npc then
                    local npcHRP = npc:FindFirstChild("HumanoidRootPart")
                    -- Di chuyển đến NPC
                    if npcHRP then
                        TweenService:Create(LocalPlayer.Character.HumanoidRootPart, TweenInfo.new(0.5), {CFrame = npcHRP.CFrame + Vector3.new(0,3,5)}):Play()
                    end
                    task.wait(0.5)
                    -- Click NPC
                    local head = npc:FindFirstChild("Head")
                    if head then
                        local pos = Workspace.CurrentCamera:WorldToViewportPoint(head.Position)
                        VirtualInputManager:SendMouseButtonEvent(pos.X, pos.Y, 0, true, game, 1)
                        task.wait(0.1)
                        VirtualInputManager:SendMouseButtonEvent(pos.X, pos.Y, 0, false, game, 1)
                    end
                    task.wait(1.5)
                    -- Tìm và click Accept
                    local pg = LocalPlayer:FindFirstChild("PlayerGui")
                    local acceptBtn = pg and (pg:FindFirstChild("Accept") or pg:FindFirstChild("Yes"))
                    if acceptBtn and acceptBtn:IsA("TextButton") then
                        local btnPos = acceptBtn.AbsolutePosition + acceptBtn.AbsoluteSize/2
                        VirtualInputManager:SendMouseButtonEvent(btnPos.X, btnPos.Y, 0, true, game, 1)
                        task.wait(0.1)
                        VirtualInputManager:SendMouseButtonEvent(btnPos.X, btnPos.Y, 0, false, game, 1)
                    end
                    task.wait(1)
                    -- Farm quái quest (lặp cho đến khi hoàn thành, thường khoảng 15s hoặc dựa vào GUI quest hoàn thành)
                    local startTime = tick()
                    while autoFarm and tick() - startTime < 20 do -- thời gian farm an toàn
                        local target = findNearestValidEnemy(200)
                        if target then
                            -- Dịch chuyển xuống dưới chân quái (không bay)
                            TweenService:Create(LocalPlayer.Character.HumanoidRootPart, TweenInfo.new(0.2), {CFrame = target.HumanoidRootPart.CFrame * CFrame.new(0, -2, 0)}):Play()
                            attack(target, spamSkillName)
                        end
                        task.wait(0.3)
                    end
                    -- Quay lại NPC nộp quest
                    if npcHRP then
                        TweenService:Create(LocalPlayer.Character.HumanoidRootPart, TweenInfo.new(0.5), {CFrame = npcHRP.CFrame + Vector3.new(0,3,5)}):Play()
                    end
                    task.wait(0.5)
                    if head then
                        local pos = Workspace.CurrentCamera:WorldToViewportPoint(head.Position)
                        VirtualInputManager:SendMouseButtonEvent(pos.X, pos.Y, 0, true, game, 1)
                        task.wait(0.1)
                        VirtualInputManager:SendMouseButtonEvent(pos.X, pos.Y, 0, false, game, 1)
                    end
                    task.wait(1.5)
                    -- Click Complete nếu có
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
                if getChakraPercent() < 30 then
                    chargeChakra()
                end
                task.wait(1)
            end
        end)
    else
        if chakraThread then task.cancel(chakraThread) end
    end
end

-- Auto Scroll
local scrollThread
function toggleAutoScroll()
    autoScroll = not autoScroll
    if autoScroll then
        scrollThread = task.spawn(function()
            while autoScroll do
                local s = findScroll()
                if s then
                    local part = s:FindFirstChild("Part") or s:FindFirstChild("Handle")
                    if part then
                        TweenService:Create(LocalPlayer.Character.HumanoidRootPart, TweenInfo.new(0.5), {CFrame = part.CFrame}):Play()
                        task.wait(0.3)
                        pcall(function() firetouchinterest(LocalPlayer.Character.HumanoidRootPart, part, 0) end)
                    end
                end
                task.wait(0.5)
            end
        end)
    else
        if scrollThread then task.cancel(scrollThread) end
    end
end

-- Skill Toggle buttons
local function createSkillToggle(key)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 50, 0, 50)
    btn.Position = keyPositions[key]  -- định nghĩa sau
    btn.BackgroundColor3 = Color3.fromRGB(100,149,237)
    btn.TextColor3 = Color3.new(1,1,1)
    btn.Font = Enum.Font.SourceSansBold
    btn.Text = key
    btn.TextSize = 20
    btn.BorderSizePixel = 0
    btn.ZIndex = 200
    btn.Parent = keyFrame
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0,8)
    local on = false
    btn.Activated:Connect(function()
        on = not on
        skillToggles[key] = on
        btn.BackgroundColor3 = on and Color3.fromRGB(34,139,34) or Color3.fromRGB(100,149,237)
    end)
    return btn
end

-- Vị trí nút kỹ năng (tùy chỉnh)
local keyPositions = {
    Y = UDim2.new(0.02, 0, 0, 5),
    N = UDim2.new(0.18, 0, 0, 5),
    B = UDim2.new(0.34, 0, 0, 5),
    V = UDim2.new(0.50, 0, 0, 5)
}

-- Giao diện kéo thả
local mainGui = Instance.new("ScreenGui")
mainGui.Name = "ShindoProFinal"
mainGui.ResetOnSpawn = false
mainGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local toggleBtn = Instance.new("TextButton")
toggleBtn.Size = UDim2.new(0, 70, 0, 70)
toggleBtn.Position = UDim2.new(0, 10, 0.5, -35)
toggleBtn.BackgroundColor3 = Color3.fromRGB(135,206,235)
toggleBtn.Text = "+"
toggleBtn.TextColor3 = Color3.new(1,1,1)
toggleBtn.Font = Enum.Font.SourceSansBold
toggleBtn.TextSize = 40
toggleBtn.BackgroundTransparency = 0.2
toggleBtn.BorderSizePixel = 0
toggleBtn.ZIndex = 100
toggleBtn.Active = true
toggleBtn.AutoButtonColor = false
toggleBtn.Parent = mainGui
Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0,12)

-- Kéo thả nút toggle và menu
local function makeDraggable(guiObject)
    local dragging = false
    local dragStartPos
    local startPos
    guiObject.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStartPos = input.Position
            startPos = guiObject.Position
        end
    end)
    guiObject.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
            local delta = input.Position - dragStartPos
            guiObject.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    guiObject.InputEnded:Connect(function()
        dragging = false
    end)
end
makeDraggable(toggleBtn)

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 300, 0, 300)
mainFrame.Position = UDim2.new(0, 100, 0.5, -150)
mainFrame.BackgroundColor3 = Color3.fromRGB(230,240,250)
mainFrame.BorderSizePixel = 0
mainFrame.Visible = false
mainFrame.Parent = mainGui
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0,12)
makeDraggable(mainFrame)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1,0,0,35)
title.BackgroundColor3 = Color3.fromRGB(173,216,230)
title.Text = "Shindo Pro Final"
title.TextColor3 = Color3.new(0,0,0.3)
title.Font = Enum.Font.SourceSansBold
title.TextSize = 16
title.Parent = mainFrame

local content = Instance.new("Frame")
content.Size = UDim2.new(1,0,1,-35)
content.Position = UDim2.new(0,0,0,35)
content.BackgroundTransparency = 1
content.Parent = mainFrame

-- Chức năng toggle
local function addToggle(text, y, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -20, 0, 35)
    btn.Position = UDim2.new(0, 10, 0, y)
    btn.BackgroundColor3 = Color3.fromRGB(100,149,237)
    btn.Text = text .. ": OFF"
    btn.TextColor3 = Color3.new(1,1,1)
    btn.Font = Enum.Font.SourceSans
    btn.TextSize = 14
    btn.BorderSizePixel = 0
    btn.Parent = content
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0,6)
    local enabled = false
    btn.Activated:Connect(function()
        enabled = not enabled
        btn.Text = text .. ": " .. (enabled and "ON" or "OFF")
        btn.BackgroundColor3 = enabled and Color3.fromRGB(34,139,34) or Color3.fromRGB(100,149,237)
        callback(enabled)
    end)
end

addToggle("Auto Farm", 10, function(on) toggleAutoFarm() end)
addToggle("Auto Chakra", 50, function(on) toggleAutoChakra() end)
addToggle("Auto Scroll", 90, function(on) toggleAutoScroll() end)

-- Nhập tên skill chính
local skillLabel = Instance.new("TextLabel")
skillLabel.Position = UDim2.new(0,10,0,140)
skillLabel.Size = UDim2.new(1,-20,0,25)
skillLabel.BackgroundTransparency = 1
skillLabel.Text = "Skill spam chính:"
skillLabel.Font = Enum.Font.SourceSans
skillLabel.TextSize = 14
skillLabel.TextColor3 = Color3.new(0,0,0.3)
skillLabel.Parent = content

local skillInput = Instance.new("TextBox")
skillInput.Position = UDim2.new(0,10,0,165)
skillInput.Size = UDim2.new(1,-20,0,30)
skillInput.BackgroundColor3 = Color3.fromRGB(100,149,237)
skillInput.TextColor3 = Color3.new(1,1,1)
skillInput.Text = spamSkillName
skillInput.Font = Enum.Font.SourceSans
skillInput.TextSize = 14
skillInput.Parent = content
skillInput.FocusLost:Connect(function()
    spamSkillName = skillInput.Text ~= "" and skillInput.Text or "Skill1"
end)

-- Nút kỹ năng ảo (Y,N,B,V) và toggle
local keyFrame = Instance.new("Frame")
keyFrame.Size = UDim2.new(1,0,0,60)
keyFrame.Position = UDim2.new(0,0,1,-70)
keyFrame.BackgroundTransparency = 1
keyFrame.Parent = mainGui

local skillButtons = {}
for key, pos in pairs(keyPositions) do
    skillButtons[key] = createSkillToggle(key)
end

-- Spam thread cho các skill được bật
task.spawn(function()
    while true do
        if autoFarm then  -- khi auto farm đang chạy, luôn spam skill chính
            local target = findNearestValidEnemy(farmRange)
            if target then attack(target, spamSkillName) end
        end
        for key, isOn in pairs(skillToggles) do
            if isOn then
                local target = findNearestValidEnemy(farmRange)
                attack(target, skillNames[key])
            end
        end
        task.wait(0.15)
    end
end)

-- Kích hoạt menu toggle
local guiVisible = false
toggleBtn.Activated:Connect(function()
    guiVisible = not guiVisible
    mainFrame.Visible = guiVisible
    toggleBtn.Text = guiVisible and "−" or "+"
end)

print("Shindo Life Pro Final loaded! Kéo thả menu thoải mái.")
