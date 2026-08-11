--[[
    SHINDO LIFE PRO MOBILE – FINAL FIX
    - Nút "+" cố định (không kéo), bấm mở menu.
    - Menu kéo thả bằng thanh tiêu đề.
    - Auto Farm Level: tự nhận quest, đánh quái (tránh gỗ, boss, player), kết hợp M1 + skill.
    - Auto Chakra: hồi khi dưới 30%.
    - Auto Scroll: nhặt scroll.
    - Bàn phím ảo Y,N,B,V: bấm để bật/tắt tự động spam skill tương ứng.
    - Tất cả hoạt động ổn định trên Delta X.
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

-- Tìm RemoteEvent
local function findRemote(name)
    -- Tìm trong ReplicatedStorage và con của Remotes
    for _, v in pairs(ReplicatedStorage:GetDescendants()) do
        if v:IsA("RemoteEvent") and v.Name == name then return v end
    end
    local remFolder = ReplicatedStorage:FindFirstChild("Remotes")
    if remFolder then
        for _, v in pairs(remFolder:GetDescendants()) do
            if v:IsA("RemoteEvent") and v.Name == name then return v end
        end
    end
    return nil
end

local damageRemote = findRemote("Damage") or findRemote("CastSpell") or findRemote("Attack")
local chakraRemote = findRemote("ChargeChakra") or findRemote("RechargeChakra")

-- Biến trạng thái
local autoFarm = false
local autoChakra = false
local autoScroll = false
local farmRange = 200
local spamSkillName = "Skill1"   -- skill chính dùng khi auto farm
local m1Enabled = true           -- kết hợp đánh thường

-- Bàn phím ảo skill (Y,N,B,V) - mỗi nút là một toggle
local skillToggles = {
    Y = false,
    N = false,
    B = false,
    V = false
}
-- Tên skill tương ứng (có thể tùy chỉnh qua TextBox)
local skillNames = {
    Y = "SkillY",
    N = "SkillN",
    B = "SkillB",
    V = "SkillV"
}

-- Hàm kiểm tra mục tiêu hợp lệ (không phải gỗ, boss, player, NPC quest)
local function isValidTarget(model)
    if not model or model == LocalPlayer.Character then return false end
    local hum = model:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return false end
    -- Bỏ qua người chơi khác
    if Players:GetPlayerFromCharacter(model) then return false end
    -- Bỏ qua boss
    if model.Name:lower():find("boss") then return false end
    -- Bỏ qua gỗ, bù nhìn, mục tiêu tập luyện
    local blacklist = {"wood", "log", "dummy", "training", "target", "maki"}
    local lowerName = model.Name:lower()
    for _, kw in ipairs(blacklist) do
        if lowerName:find(kw) then return false end
    end
    -- Bỏ qua NPC nhiệm vụ (có dấu "!" trên đầu)
    local head = model:FindFirstChild("Head")
    if head then
        for _, gui in pairs(head:GetChildren()) do
            if gui:IsA("BillboardGui") then
                local textLabel = gui:FindFirstChild("TextLabel")
                local imageLabel = gui:FindFirstChild("ImageLabel")
                if textLabel and textLabel.Text == "!" then return false end
                if imageLabel and imageLabel.Image:find("exclamation") then return false end
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
    for _, obj in pairs(Workspace:GetDescendants()) do
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
    -- Tìm NPC có dấu chấm than "!" (nhiệm vụ chính)
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") then
            local hum = obj:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then
                local head = obj:FindFirstChild("Head")
                if head then
                    for _, gui in pairs(head:GetChildren()) do
                        if gui:IsA("BillboardGui") then
                            local tl = gui:FindFirstChild("TextLabel")
                            local il = gui:FindFirstChild("ImageLabel")
                            if (tl and tl.Text == "!") or (il and il.Image:find("exclamation")) then
                                return obj
                            end
                        end
                    end
                end
                -- Dự phòng nếu tên chứa "quest"
                if obj.Name:lower():find("quest") then
                    return obj
                end
            end
        end
    end
    return nil
end

local function findScroll()
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") and (obj.Name:lower():find("scroll") or obj.Name:lower():find("paper")) then
            return obj
        end
    end
    return nil
end

-- Tấn công (kết hợp M1 và skill)
local function attackTarget(target, skillName)
    if not target then return end
    skillName = skillName or spamSkillName
    -- Đánh thường (M1) nếu được bật
    if m1Enabled then
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
        task.wait(0.08)
    end
    -- Dùng skill
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
        -- Giả lập phím C (thường dùng để nạp chakra)
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.C, false, game)
        task.wait(0.1)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.C, false, game)
    end
end

local function getChakraPercent()
    local char = LocalPlayer.Character
    if not char then return 100 end
    local chakraVal = char:FindFirstChild("Chakra")
    if chakraVal and chakraVal:IsA("NumberValue") then
        local maxVal = char:FindFirstChild("MaxChakra") or char:FindFirstChild("MaxChakraValue")
        local max = (maxVal and maxVal:IsA("NumberValue") and maxVal.Value) or 100
        return (chakraVal.Value / max) * 100
    end
    return 100
end

-- ================== CHỨC NĂNG CHÍNH ==================
local farmThread
function toggleAutoFarm()
    autoFarm = not autoFarm
    if autoFarm then
        farmThread = task.spawn(function()
            while autoFarm do
                local npc = findQuestNPC()
                if npc then
                    local npcHRP = npc:FindFirstChild("HumanoidRootPart")
                    -- Di chuyển đến NPC
                    if npcHRP then
                        TweenService:Create(LocalPlayer.Character.HumanoidRootPart, TweenInfo.new(0.5), {CFrame = npcHRP.CFrame + Vector3.new(0,3,5)}):Play()
                    end
                    task.wait(0.5)
                    -- Click vào NPC để mở hội thoại
                    local head = npc:FindFirstChild("Head")
                    if head then
                        local pos = Workspace.CurrentCamera:WorldToViewportPoint(head.Position)
                        VirtualInputManager:SendMouseButtonEvent(pos.X, pos.Y, 0, true, game, 1)
                        task.wait(0.1)
                        VirtualInputManager:SendMouseButtonEvent(pos.X, pos.Y, 0, false, game, 1)
                    end
                    task.wait(1.5)
                    -- Tìm nút "Accept" trong PlayerGui và click
                    local pg = LocalPlayer:FindFirstChild("PlayerGui")
                    local acceptBtn = pg and (pg:FindFirstChild("Accept") or pg:FindFirstChild("Yes") or pg:FindFirstChild("OK"))
                    if acceptBtn and acceptBtn:IsA("TextButton") then
                        local btnPos = acceptBtn.AbsolutePosition + acceptBtn.AbsoluteSize/2
                        VirtualInputManager:SendMouseButtonEvent(btnPos.X, btnPos.Y, 0, true, game, 1)
                        task.wait(0.1)
                        VirtualInputManager:SendMouseButtonEvent(btnPos.X, btnPos.Y, 0, false, game, 1)
                    end
                    task.wait(1)
                    -- Farm quái trong 20 giây (đủ để hoàn thành nhiệm vụ thông thường)
                    local startTime = tick()
                    while autoFarm and (tick() - startTime) < 20 do
                        local target = findNearestValidEnemy(200)
                        if target then
                            -- Đứng dưới đất, sát mục tiêu
                            TweenService:Create(LocalPlayer.Character.HumanoidRootPart, TweenInfo.new(0.2), {CFrame = target.HumanoidRootPart.CFrame * CFrame.new(0, -2, 0)}):Play()
                            attackTarget(target, spamSkillName)
                        end
                        task.wait(0.25)
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
                    -- Tìm nút "Complete" hoặc "Claim"
                    local completeBtn = pg and (pg:FindFirstChild("Complete") or pg:FindFirstChild("Claim") or pg:FindFirstChild("Finish"))
                    if completeBtn and completeBtn:IsA("TextButton") then
                        local btnPos = completeBtn.AbsolutePosition + completeBtn.AbsoluteSize/2
                        VirtualInputManager:SendMouseButtonEvent(btnPos.X, btnPos.Y, 0, true, game, 1)
                        task.wait(0.1)
                        VirtualInputManager:SendMouseButtonEvent(btnPos.X, btnPos.Y, 0, false, game, 1)
                    end
                    task.wait(2)
                else
                    task.wait(2) -- không tìm thấy NPC, thử lại sau
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

-- ================== GIAO DIỆN ==================
local mainGui = Instance.new("ScreenGui")
mainGui.Name = "ShindoProFinalFix"
mainGui.ResetOnSpawn = false
mainGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

-- Nút toggle cố định (không kéo thả) – dùng MouseButton1Click và Activated
local toggleBtn = Instance.new("TextButton")
toggleBtn.Size = UDim2.new(0, 70, 0, 70)
toggleBtn.Position = UDim2.new(0, 10, 0.5, -35)
toggleBtn.BackgroundColor3 = Color3.fromRGB(135, 206, 235)  -- xanh nhạt
toggleBtn.Text = "+"
toggleBtn.TextColor3 = Color3.new(1, 1, 1)
toggleBtn.Font = Enum.Font.SourceSansBold
toggleBtn.TextSize = 40
toggleBtn.BackgroundTransparency = 0.2
toggleBtn.BorderSizePixel = 0
toggleBtn.ZIndex = 100
toggleBtn.Active = true
toggleBtn.AutoButtonColor = false
toggleBtn.Parent = mainGui
Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0, 12)

local guiVisible = false
local mainFrame

-- Hàm bật/tắt menu
local function toggleMenu()
    guiVisible = not guiVisible
    if mainFrame then
        mainFrame.Visible = guiVisible
    end
    toggleBtn.Text = guiVisible and "−" or "+"
end

-- Sử dụng cả MouseButton1Click (cho PC/giả lập) và Activated (cho mobile)
toggleBtn.MouseButton1Click:Connect(toggleMenu)
toggleBtn.Activated:Connect(toggleMenu)

-- Khung menu chính (có thể kéo thả qua thanh tiêu đề)
mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 300, 0, 320)
mainFrame.Position = UDim2.new(0, 100, 0.5, -160)
mainFrame.BackgroundColor3 = Color3.fromRGB(230, 240, 250)
mainFrame.BorderSizePixel = 0
mainFrame.Visible = false
mainFrame.ClipsDescendants = true
mainFrame.Parent = mainGui
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 12)

-- Thanh tiêu đề (dùng để kéo thả menu)
local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 35)
titleBar.BackgroundColor3 = Color3.fromRGB(173, 216, 230)
titleBar.BorderSizePixel = 0
titleBar.Parent = mainFrame

local titleText = Instance.new("TextLabel")
titleText.Size = UDim2.new(1, 0, 1, 0)
titleText.BackgroundTransparency = 1
titleText.Text = "Shindo Pro v3.0 FINAL"
titleText.TextColor3 = Color3.new(0, 0, 0.3)
titleText.Font = Enum.Font.SourceSansBold
titleText.TextSize = 16
titleText.Parent = titleBar

-- Kéo thả menu
local dragging, dragStartPos, startPos
titleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStartPos = input.Position
        startPos = mainFrame.Position
        input.UserInputState = Enum.UserInputState.Began
    end
end)
titleBar.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
        local delta = input.Position - dragStartPos
        mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)
titleBar.InputEnded:Connect(function(input)
    dragging = false
end)

-- Nội dung menu
local content = Instance.new("Frame")
content.Size = UDim2.new(1, 0, 1, -35)
content.Position = UDim2.new(0, 0, 0, 35)
content.BackgroundTransparency = 1
content.Parent = mainFrame

-- Hàm tạo nút toggle chức năng
local function addToggleButton(text, y, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -20, 0, 35)
    btn.Position = UDim2.new(0, 10, 0, y)
    btn.BackgroundColor3 = Color3.fromRGB(100, 149, 237)
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.Font = Enum.Font.SourceSans
    btn.Text = text .. ": OFF"
    btn.TextSize = 14
    btn.BorderSizePixel = 0
    btn.Parent = content
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    local enabled = false
    btn.MouseButton1Click:Connect(function()
        enabled = not enabled
        btn.Text = text .. ": " .. (enabled and "ON" or "OFF")
        btn.BackgroundColor3 = enabled and Color3.fromRGB(34, 139, 34) or Color3.fromRGB(100, 149, 237)
        callback(enabled)
    end)
    btn.Activated:Connect(function() -- dự phòng
        enabled = not enabled
        btn.Text = text .. ": " .. (enabled and "ON" or "OFF")
        btn.BackgroundColor3 = enabled and Color3.fromRGB(34, 139, 34) or Color3.fromRGB(100, 149, 237)
        callback(enabled)
    end)
    return btn
end

-- Nút chức năng
addToggleButton("Auto Farm", 10, function(on) toggleAutoFarm() end)
addToggleButton("Auto Chakra", 50, function(on) toggleAutoChakra() end)
addToggleButton("Auto Scroll", 90, function(on) toggleAutoScroll() end)

-- Cài đặt skill chính
local skillLabel = Instance.new("TextLabel")
skillLabel.Size = UDim2.new(1, -20, 0, 25)
skillLabel.Position = UDim2.new(0, 10, 0, 140)
skillLabel.BackgroundTransparency = 1
skillLabel.Text = "Skill spam chính:"
skillLabel.TextColor3 = Color3.new(0, 0, 0.3)
skillLabel.Font = Enum.Font.SourceSans
skillLabel.TextSize = 14
skillLabel.Parent = content

local skillInput = Instance.new("TextBox")
skillInput.Size = UDim2.new(1, -20, 0, 30)
skillInput.Position = UDim2.new(0, 10, 0, 165)
skillInput.BackgroundColor3 = Color3.fromRGB(100, 149, 237)
skillInput.TextColor3 = Color3.new(1, 1, 1)
skillInput.PlaceholderText = "Nhập tên skill..."
skillInput.Text = spamSkillName
skillInput.Font = Enum.Font.SourceSans
skillInput.TextSize = 14
skillInput.Parent = content
skillInput.FocusLost:Connect(function()
    spamSkillName = skillInput.Text ~= "" and skillInput.Text or "Skill1"
end)

-- Cấu hình skill cho các nút Y,N,B,V
local keyCfgLabel = Instance.new("TextLabel")
keyCfgLabel.Size = UDim2.new(1, -20, 0, 25)
keyCfgLabel.Position = UDim2.new(0, 10, 0, 205)
keyCfgLabel.BackgroundTransparency = 1
keyCfgLabel.Text = "Skill cho Y / N / B / V:"
keyCfgLabel.TextColor3 = Color3.new(0, 0, 0.3)
keyCfgLabel.Font = Enum.Font.SourceSans
keyCfgLabel.TextSize = 14
keyCfgLabel.Parent = content

local keys = {"Y", "N", "B", "V"}
local keyInputs = {}
for i, key in ipairs(keys) do
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0, 20, 0, 25)
    label.Position = UDim2.new(0, 10, 0, 230 + (i-1)*30)
    label.BackgroundTransparency = 1
    label.Text = key
    label.TextColor3 = Color3.new(0, 0, 0.3)
    label.Font = Enum.Font.SourceSansBold
    label.TextSize = 14
    label.Parent = content

    local input = Instance.new("TextBox")
    input.Size = UDim2.new(1, -35, 0, 25)
    input.Position = UDim2.new(0, 35, 0, 230 + (i-1)*30)
    input.BackgroundColor3 = Color3.fromRGB(100, 149, 237)
    input.TextColor3 = Color3.new(1, 1, 1)
    input.Text = skillNames[key]
    input.Font = Enum.Font.SourceSans
    input.TextSize = 14
    input.Parent = content
    input.FocusLost:Connect(function()
        skillNames[key] = input.Text ~= "" and input.Text or skillNames[key]
    end)
    keyInputs[key] = input
end

-- ================== BÀN PHÍM ẢO (Y,N,B,V) ==================
local keyFrame = Instance.new("Frame")
keyFrame.Size = UDim2.new(1, 0, 0, 60)
keyFrame.Position = UDim2.new(0, 0, 1, -70)
keyFrame.BackgroundTransparency = 1
keyFrame.Parent = mainGui

local keyPositions = {
    Y = UDim2.new(0.02, 0, 0, 5),
    N = UDim2.new(0.18, 0, 0, 5),
    B = UDim2.new(0.34, 0, 0, 5),
    V = UDim2.new(0.50, 0, 0, 5)
}

local function createSkillToggle(key, position)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 50, 0, 50)
    btn.Position = position
    btn.BackgroundColor3 = Color3.fromRGB(100, 149, 237)
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.Font = Enum.Font.SourceSansBold
    btn.Text = key
    btn.TextSize = 20
    btn.BorderSizePixel = 0
    btn.ZIndex = 200
    btn.Parent = keyFrame
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
    local on = false
    btn.MouseButton1Click:Connect(function()
        on = not on
        skillToggles[key] = on
        btn.BackgroundColor3 = on and Color3.fromRGB(34, 139, 34) or Color3.fromRGB(100, 149, 237)
    end)
    btn.Activated:Connect(function()
        on = not on
        skillToggles[key] = on
        btn.BackgroundColor3 = on and Color3.fromRGB(34, 139, 34) or Color3.fromRGB(100, 149, 237)
    end)
    return btn
end

for key, pos in pairs(keyPositions) do
    createSkillToggle(key, pos)
end

-- ================== VÒNG LẶP SPAM SKILL ==================
task.spawn(function()
    while true do
        -- Nếu auto farm đang bật, spam skill chính vào mục tiêu gần nhất
        if autoFarm then
            local target = findNearestValidEnemy(farmRange)
            if target then
                attackTarget(target, spamSkillName)
            end
        end
        -- Spam skill riêng cho từng nút bật
        for key, isOn in pairs(skillToggles) do
            if isOn then
                local target = findNearestValidEnemy(farmRange)
                attackTarget(target, skillNames[key])
            end
        end
        task.wait(0.15)
    end
end)

print("Shindo Life Pro Final loaded! Bấm nút '+' xanh để mở menu.")
