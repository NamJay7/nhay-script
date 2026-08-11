--[[
    SHINDO LIFE PRO MOBILE FINAL v2 – SỬA LỖI NÚT TOGGLE KHÔNG HIỆN MENU
    - Nút "+" có thể kéo thả tự do.
    - Chạm nhẹ (tap) để mở menu, kéo để di chuyển nút.
    - Tất cả tính năng giữ nguyên: Auto Farm, Auto Chakra, Auto Scroll, Spam Skill ảo.
    - Phân biệt quái/gỗ/boss/player, tự nhận/nộp quest, vị trí farm an toàn.
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

-- Tìm Remote
local function findRemote(name)
    for _, v in ipairs(ReplicatedStorage:GetDescendants()) do
        if v:IsA("RemoteEvent") and v.Name == name then return v end
    end
    local rem = ReplicatedStorage:FindFirstChild("Remotes")
    if rem then for _, v in ipairs(rem:GetDescendants()) do if v:IsA("RemoteEvent") and v.Name == name then return v end end end
    return nil
end

local damageRemote = findRemote("Damage") or findRemote("CastSpell") or findRemote("Attack")
local rankUpRemote = findRemote("RankUp") or findRemote("Promote")
local chakraRemote = findRemote("ChargeChakra") or findRemote("RechargeChakra")

-- Biến
local autoFarm = false
local autoChakra = false
local autoScroll = false
local farmRange = 200
local spamSkillName = "Skill1"
local m1Enabled = true

-- Bàn phím ảo skill toggle
local skillToggles = { Y = false, N = false, B = false, V = false }
local skillNames = { Y = "SkillY", N = "SkillN", B = "SkillB", V = "SkillV" }

-- Hàm kiểm tra quái hợp lệ
local function isValidTarget(model)
    if not model or model == LocalPlayer.Character then return false end
    local hum = model:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return false end
    if Players:GetPlayerFromCharacter(model) then return false end
    if model.Name:lower():find("boss") then return false end
    local blacklist = {"wood", "log", "dummy", "training", "target", "maki"}
    local lname = model.Name:lower()
    for _, kw in ipairs(blacklist) do if lname:find(kw) then return false end end
    local head = model:FindFirstChild("Head")
    if head then
        for _, gui in ipairs(head:GetChildren()) do
            if gui:IsA("BillboardGui") and gui:FindFirstChild("TextLabel") and gui.TextLabel.Text == "!" then return false end
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
                            if (tl and tl.Text == "!") or (il and il.Image:find("exclamation")) then return obj end
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
        if obj:IsA("Model") and (obj.Name:lower():find("scroll") or obj.Name:lower():find("paper")) then return obj end
    end
    return nil
end

-- Tấn công kết hợp M1 + skill
local function attack(target, skillName)
    if not target then return end
    skillName = skillName or spamSkillName
    if m1Enabled then
        if damageRemote then pcall(function() damageRemote:FireServer(target, "M1") end)
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
    if damageRemote then pcall(function() damageRemote:FireServer(target, skillName) end)
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
    if chakraRemote then pcall(function() chakraRemote:FireServer() end)
    else VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.C, false, game) task.wait(0.1) VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.C, false, game) end
end

local function getChakraPercent()
    local char = LocalPlayer.Character
    if not char then return 100 end
    local val = char:FindFirstChild("Chakra")
    if val and val:IsA("NumberValue") then
        local max = char:FindFirstChild("MaxChakra") or char:FindFirstChild("MaxChakraValue")
        local maxVal = max and max:IsA("NumberValue") and max.Value or 100
        return (val.Value / maxVal) * 100
    end
    return 100
end

-- Auto Farm (nhận quest, đánh quái)
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
                    while autoFarm and tick() - startTime < 20 do
                        local target = findNearestValidEnemy(200)
                        if target then
                            TweenService:Create(LocalPlayer.Character.HumanoidRootPart, TweenInfo.new(0.2), {CFrame = target.HumanoidRootPart.CFrame * CFrame.new(0, -2, 0)}):Play()
                            attack(target, spamSkillName)
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
    else if chakraThread then task.cancel(chakraThread) end
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
    else if scrollThread then task.cancel(scrollThread) end
    end
end

-- Bàn phím ảo skill toggle
local function createSkillToggle(key, position)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 50, 0, 50)
    btn.Position = position
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

-- Giao diện
local mainGui = Instance.new("ScreenGui")
mainGui.Name = "ShindoProFinal"
mainGui.ResetOnSpawn = false
mainGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

-- Nút toggle kéo thả + tap
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

-- Hệ thống kéo / tap cho nút toggle
local dragStartPos, startPos, dragStartTime, isDrag = nil, nil, nil, false
local clickThreshold = 0.3 -- 0.3 giây
local moveThreshold = 5 -- pixel

toggleBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        isDrag = true
        dragStartPos = input.Position
        startPos = toggleBtn.Position
        dragStartTime = tick()
    end
end)

toggleBtn.InputChanged:Connect(function(input)
    if isDrag and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
        local delta = input.Position - dragStartPos
        -- Nếu vượt ngưỡng thì coi là kéo, không phải tap
        if math.abs(delta.X) > moveThreshold or math.abs(delta.Y) > moveThreshold then
            isDrag = false -- sau này sẽ không coi là tap nữa
        end
        toggleBtn.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

toggleBtn.InputEnded:Connect(function(input)
    if not isDrag then return end
    local delta = input.Position - dragStartPos
    local elapsed = tick() - dragStartTime
    -- Nếu di chuyển ít và thời gian ngắn -> tap
    if elapsed < clickThreshold and math.abs(delta.X) < moveThreshold and math.abs(delta.Y) < moveThreshold then
        guiVisible = not guiVisible
        mainFrame.Visible = guiVisible
        toggleBtn.Text = guiVisible and "−" or "+"
    end
    isDrag = false
end)

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 300, 0, 300)
mainFrame.Position = UDim2.new(0, 100, 0.5, -150)
mainFrame.BackgroundColor3 = Color3.fromRGB(230,240,250)
mainFrame.BorderSizePixel = 0
mainFrame.Visible = false
mainFrame.Parent = mainGui
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0,12)

-- Cho phép kéo thả mainFrame nhưng không ảnh hưởng đến thao tác bên trong
local mfDragPos, mfStartPos, mfDragging = nil, nil, false
mainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        mfDragging = true
        mfDragPos = input.Position
        mfStartPos = mainFrame.Position
        input.UserInputState = Enum.UserInputState.Began
    end
end)
mainFrame.InputChanged:Connect(function(input)
    if mfDragging and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
        local delta = input.Position - mfDragPos
        mainFrame.Position = UDim2.new(mfStartPos.X.Scale, mfStartPos.X.Offset + delta.X, mfStartPos.Y.Scale, mfStartPos.Y.Offset + delta.Y)
    end
end)
mainFrame.InputEnded:Connect(function() mfDragging = false end)

-- Nội dung menu
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1,0,0,35)
title.BackgroundColor3 = Color3.fromRGB(173,216,230)
title.Text = "Shindo Pro Final v2"
title.TextColor3 = Color3.new(0,0,0.3)
title.Font = Enum.Font.SourceSansBold
title.TextSize = 16
title.Parent = mainFrame

local content = Instance.new("Frame")
content.Size = UDim2.new(1,0,1,-35)
content.Position = UDim2.new(0,0,0,35)
content.BackgroundTransparency = 1
content.Parent = mainFrame

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

addToggle("Auto Farm", 10, toggleAutoFarm)
addToggle("Auto Chakra", 50, toggleAutoChakra)
addToggle("Auto Scroll", 90, toggleAutoScroll)

local skillLabel = Instance.new("TextLabel")
skillLabel.Position = UDim2.new(0,10,0,140)
skillLabel.Size = UDim2.new(1,-20,0,25)
skillLabel.BackgroundTransparency = 1
skillLabel.Text = "Skill spam chính:"
skillLabel.Font = Enum.Font.SourceSans; skillLabel.TextSize = 14; skillLabel.TextColor3 = Color3.new(0,0,0.3)
skillLabel.Parent = content

local skillInput = Instance.new("TextBox")
skillInput.Position = UDim2.new(0,10,0,165)
skillInput.Size = UDim2.new(1,-20,0,30)
skillInput.BackgroundColor3 = Color3.fromRGB(100,149,237)
skillInput.TextColor3 = Color3.new(1,1,1)
skillInput.Text = spamSkillName
skillInput.Font = Enum.Font.SourceSans; skillInput.TextSize = 14
skillInput.Parent = content
skillInput.FocusLost:Connect(function() spamSkillName = skillInput.Text ~= "" and skillInput.Text or "Skill1" end)

-- Khung chứa nút kỹ năng ảo (luôn hiện)
local keyFrame = Instance.new("Frame")
keyFrame.Size = UDim2.new(1,0,0,60)
keyFrame.Position = UDim2.new(0,0,1,-70)
keyFrame.BackgroundTransparency = 1
keyFrame.Parent = mainGui

local keyPositions = {
    Y = UDim2.new(0.02, 0, 0, 5),
    N = UDim2.new(0.18, 0, 0, 5),
    B = UDim2.new(0.34, 0, 0, 5),
    V = UDim2.new(0.50, 0, 0, 5)
}
for key, pos in pairs(keyPositions) do createSkillToggle(key, pos) end

-- Spam skill (chạy nền)
task.spawn(function()
    while true do
        if autoFarm then
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

print("Shindo Pro Final v2: Kéo nút '+' để di chuyển, chạm nhẹ để mở menu.")
