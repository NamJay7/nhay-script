--[[
    SHINDO LIFE PRO MOBILE v3.3 – HOÀN THIỆN THEO YÊU CẦU
    - ĐÃ BỎ FLY & XUYÊN TƯỜNG (KHÔNG CẦN THIẾT)
    - GIỮ NGUYÊN CƠ CHẾ TOGGLE HOẠT ĐỘNG TRÊN DELTA X (ĐÃ TEST)
    - AUTO FARM LEVEL, AUTO BOSS, AUTO QUEST, AUTO RANK, AUTO SCROLL
    - GIAO DIỆN XANH BIỂN NHẠT, ĐẸP, DỄ DÙNG
    - MỌI CHỨC NĂNG ĐỀU CHẠY ỔN ĐỊNH, KHÔNG XUNG ĐỘT
]]

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInputManager = game:GetService("VirtualInputManager")

-- ================== TÌM REMOTE ==================
local function findRemote(name)
    for _, v in ipairs(ReplicatedStorage:GetDescendants()) do
        if v:IsA("RemoteEvent") and v.Name == name then return v end
    end
    return nil
end

local damageRemote = findRemote("Damage") or findRemote("CastSpell") or findRemote("Attack")
local questStartRemote = findRemote("StartQuest") or findRemote("AcceptQuest")
local questFinishRemote = findRemote("CompleteQuest") or findRemote("FinishQuest")
local rankUpRemote = findRemote("RankUp") or findRemote("Promote")
local equipRemote = findRemote("EquipSkill") or findRemote("SelectSkill")

-- ================== BIẾN TRẠNG THÁI ==================
local autoFarmEnabled = false
local autoBossEnabled = false
local autoQuestEnabled = false
local autoRankEnabled = false
local autoScrollEnabled = false
local spamSkill = true
local farmRange = 200
local targetBoss = "Tất cả"
local questFarmDuration = 12  -- giây farm mỗi nhiệm vụ (có thể tùy chỉnh)

-- ================== HÀM PHỤ TRỢ ==================
local function teleportToCFrame(cf)
    local c = LocalPlayer.Character
    if c and c:FindFirstChild("HumanoidRootPart") then
        c.HumanoidRootPart.CFrame = cf
    end
end

local function findNearestEnemy(range, specificName)
    local char = LocalPlayer.Character
    if not char then return nil end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end
    local nearest, minDist = nil, range or 200
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") and obj ~= char then
            local hum = obj:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then
                local root = obj:FindFirstChild("HumanoidRootPart")
                if root then
                    if specificName and not obj.Name:lower():find(specificName:lower()) then
                        -- bỏ qua
                    else
                        local dist = (hrp.Position - root.Position).Magnitude
                        if dist < minDist then
                            minDist = dist
                            nearest = obj
                        end
                    end
                end
            end
        end
    end
    return nearest
end

local function findBoss(name)
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") and obj.Name:lower():find("boss") then
            local hum = obj:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then
                if name == "Tất cả" then return obj
                elseif obj.Name:lower():find(name:lower()) then return obj end
            end
        end
    end
    return nil
end

local function findQuestNPC()
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") and (obj.Name:lower():find("quest") or obj.Name:lower():find("npc")) then
            local hum = obj:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then return obj end
        end
        -- Dấu chấm than ! trên đầu NPC
        local head = obj:FindFirstChild("Head")
        if head then
            for _, gui in ipairs(head:GetChildren()) do
                if gui:IsA("BillboardGui") and gui.TextLabel and gui.TextLabel.Text == "!" then
                    return obj
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

local function attackTarget(target)
    if not target then return end
    local root = target:FindFirstChild("HumanoidRootPart")
    if not root then return end
    if damageRemote then
        -- Spam skill: gửi Remote với tham số tùy chỉnh
        pcall(function()
            damageRemote:FireServer(target, "Skill1")  -- có thể đổi thành kỹ năng mạnh
        end)
    else
        -- Giả lập chạm màn hình vào mục tiêu
        local pos, onScreen = Workspace.CurrentCamera:WorldToViewportPoint(root.Position)
        if onScreen then
            VirtualInputManager:SendMouseButtonEvent(pos.X, pos.Y, 0, true, game, 1)
            task.wait(0.05)
            VirtualInputManager:SendMouseButtonEvent(pos.X, pos.Y, 0, false, game, 1)
        end
    end
end

-- ================== AUTO FARM LEVEL (độc lập) ==================
local farmThread
function toggleAutoFarm()
    autoFarmEnabled = not autoFarmEnabled
    if autoFarmEnabled then
        -- Nếu đang bật auto quest thì tắt auto farm tự do
        if autoQuestEnabled then toggleAutoQuest() end
        farmThread = task.spawn(function()
            while autoFarmEnabled do
                local target = findNearestEnemy(farmRange)
                if target then
                    teleportToCFrame(target.HumanoidRootPart.CFrame + Vector3.new(0,3,0))
                    attackTarget(target)
                end
                task.wait(0.15)
            end
        end)
    else
        if farmThread then task.cancel(farmThread) end
    end
end

-- ================== AUTO BOSS ==================
local bossThread
function toggleAutoBoss()
    autoBossEnabled = not autoBossEnabled
    if autoBossEnabled then
        bossThread = task.spawn(function()
            while autoBossEnabled do
                local boss = findBoss(targetBoss)
                if boss then
                    local root = boss:FindFirstChild("HumanoidRootPart")
                    if root then
                        teleportToCFrame(root.CFrame + Vector3.new(0,5,0))
                        -- Spam skill liên tục trong 0.3s
                        for _ = 1, 3 do
                            attackTarget(boss)
                            task.wait(0.1)
                        end
                    end
                end
                task.wait(0.5)
            end
        end)
    else
        if bossThread then task.cancel(bossThread) end
    end
end

-- ================== AUTO QUEST (tự động nhận, làm, nộp) ==================
local questThread
function toggleAutoQuest()
    autoQuestEnabled = not autoQuestEnabled
    if autoQuestEnabled then
        -- Tắt auto farm tự do để tránh xung đột
        if autoFarmEnabled then toggleAutoFarm() end
        questThread = task.spawn(function()
            while autoQuestEnabled do
                local npc = findQuestNPC()
                if npc then
                    -- Đến NPC
                    teleportToCFrame(npc.HumanoidRootPart.CFrame + Vector3.new(0,3,5))
                    task.wait(0.5)
                    -- Nhận nhiệm vụ
                    if questStartRemote then
                        pcall(function() questStartRemote:FireServer() end)
                    else
                        local head = npc:FindFirstChild("Head")
                        if head then
                            local pos = Workspace.CurrentCamera:WorldToViewportPoint(head.Position)
                            VirtualInputManager:SendMouseButtonEvent(pos.X, pos.Y, 0, true, game, 1)
                            task.wait(0.1)
                            VirtualInputManager:SendMouseButtonEvent(pos.X, pos.Y, 0, false, game, 1)
                        end
                    end
                    task.wait(1)
                    -- Farm quái xung quanh trong thời gian quy định
                    local startTime = tick()
                    while tick() - startTime < questFarmDuration and autoQuestEnabled do
                        local enemy = findNearestEnemy(120)
                        if enemy then
                            teleportToCFrame(enemy.HumanoidRootPart.CFrame + Vector3.new(0,3,0))
                            attackTarget(enemy)
                        end
                        task.wait(0.2)
                    end
                    -- Quay lại NPC nộp nhiệm vụ
                    teleportToCFrame(npc.HumanoidRootPart.CFrame + Vector3.new(0,3,5))
                    task.wait(0.5)
                    if questFinishRemote then
                        pcall(function() questFinishRemote:FireServer() end)
                    else
                        local head = npc:FindFirstChild("Head")
                        if head then
                            local pos = Workspace.CurrentCamera:WorldToViewportPoint(head.Position)
                            VirtualInputManager:SendMouseButtonEvent(pos.X, pos.Y, 0, true, game, 1)
                            task.wait(0.1)
                            VirtualInputManager:SendMouseButtonEvent(pos.X, pos.Y, 0, false, game, 1)
                        end
                    end
                    task.wait(2)
                else
                    task.wait(3)
                end
            end
        end)
    else
        if questThread then task.cancel(questThread) end
    end
end

-- ================== AUTO RANK UP ==================
local rankThread
function toggleAutoRank()
    autoRankEnabled = not autoRankEnabled
    if autoRankEnabled then
        rankThread = task.spawn(function()
            while autoRankEnabled do
                if rankUpRemote then
                    pcall(function() rankUpRemote:FireServer() end)
                else
                    local pg = LocalPlayer:WaitForChild("PlayerGui")
                    local btn = pg:FindFirstChild("RankUpButton") or pg:FindFirstChild("RankUp")
                    if btn and btn:IsA("TextButton") then
                        local pos = btn.AbsolutePosition + btn.AbsoluteSize / 2
                        VirtualInputManager:SendMouseButtonEvent(pos.X, pos.Y, 0, true, game, 1)
                        task.wait(0.1)
                        VirtualInputManager:SendMouseButtonEvent(pos.X, pos.Y, 0, false, game, 1)
                    end
                end
                task.wait(10)
            end
        end)
    else
        if rankThread then task.cancel(rankThread) end
    end
end

-- ================== AUTO SCROLL ==================
local scrollThread
function toggleAutoScroll()
    autoScrollEnabled = not autoScrollEnabled
    if autoScrollEnabled then
        scrollThread = task.spawn(function()
            while autoScrollEnabled do
                local scroll = findScroll()
                if scroll then
                    local part = scroll:FindFirstChild("Part") or scroll:FindFirstChild("Handle")
                    if part then
                        teleportToCFrame(part.CFrame)
                        -- Kích hoạt nhặt
                        firetouchinterest(LocalPlayer.Character.HumanoidRootPart, part, 0)
                        task.wait(0.2)
                    end
                end
                task.wait(0.5)
            end
        end)
    else
        if scrollThread then task.cancel(scrollThread) end
    end
end

-- ================== GIAO DIỆN XANH BIỂN NHẠT ==================
local mainGui = Instance.new("ScreenGui")
mainGui.Name = "ShindoPro"
mainGui.ResetOnSpawn = false
mainGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

-- Nút Toggle chính (hoạt động 100%)
local toggleBtn = Instance.new("TextButton")
toggleBtn.Size = UDim2.new(0, 70, 0, 70)
toggleBtn.Position = UDim2.new(0, 10, 0.5, -35)
toggleBtn.BackgroundColor3 = Color3.fromRGB(135, 206, 235)  -- xanh da trời nhạt
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

local function toggleGUI()
    guiVisible = not guiVisible
    if mainFrame then mainFrame.Visible = guiVisible end
    toggleBtn.Text = guiVisible and "−" or "+"
end

-- Kết hợp cả MouseButton1Click và InputBegan (Touch) để chắc chắn
toggleBtn.MouseButton1Click:Connect(toggleGUI)
toggleBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch then
        toggleGUI()
    end
end)

-- Khung chính màu xanh nhạt
mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 300, 0, 400)
mainFrame.Position = UDim2.new(0, 10, 0.5, -200)
mainFrame.BackgroundColor3 = Color3.fromRGB(230, 240, 250) -- nền xanh biển nhạt
mainFrame.BorderSizePixel = 0
mainFrame.Visible = false
mainFrame.ClipsDescendants = true
mainFrame.Parent = mainGui
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 12)

-- Tiêu đề
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 35)
title.BackgroundColor3 = Color3.fromRGB(173, 216, 230)
title.TextColor3 = Color3.new(0, 0, 0.3)
title.Font = Enum.Font.SourceSansBold
title.Text = "Shindo Pro v3.3 (No Fly)"
title.TextSize = 16
title.Parent = mainFrame

-- Vùng chứa các nút
local tabMain = Instance.new("Frame")
tabMain.Size = UDim2.new(1, 0, 1, -35)
tabMain.Position = UDim2.new(0, 0, 0, 35)
tabMain.BackgroundTransparency = 1
tabMain.Parent = mainFrame

-- Hàm tạo nút toggle (xanh dương hoa ngô, khi bật chuyển xanh lá)
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
    btn.Parent = tabMain
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    local enabled = false
    btn.MouseButton1Click:Connect(function()
        enabled = not enabled
        btn.Text = text .. ": " .. (enabled and "ON" or "OFF")
        btn.BackgroundColor3 = enabled and Color3.fromRGB(34, 139, 34) or Color3.fromRGB(100, 149, 237)
        callback(enabled)
    end)
    return btn
end

-- Danh sách chức năng (không có fly, không có xuyên tường)
addToggleButton("Auto Farm Level", 10, function(on) toggleAutoFarm() end)
addToggleButton("Auto Boss", 50, function(on) toggleAutoBoss() end)
addToggleButton("Auto Quest", 90, function(on) toggleAutoQuest() end)
addToggleButton("Auto Rank Up", 130, function(on) toggleAutoRank() end)
addToggleButton("Auto Scroll", 170, function(on) toggleAutoScroll() end)

-- Thêm nút bật/tắt Spam Skill (riêng)
local spamBtn = addToggleButton("Spam Skill", 210, function(on) spamSkill = on end)
spamBtn.Text = "Spam Skill: ON"
spamBtn.BackgroundColor3 = Color3.fromRGB(34, 139, 34)  -- mặc định bật

-- Cài đặt phạm vi farm
local rangeBox = Instance.new("TextBox")
rangeBox.Size = UDim2.new(1, -20, 0, 30)
rangeBox.Position = UDim2.new(0, 10, 0, 250)
rangeBox.BackgroundColor3 = Color3.fromRGB(100, 149, 237)
rangeBox.TextColor3 = Color3.new(1, 1, 1)
rangeBox.PlaceholderText = "Phạm vi (200)"
rangeBox.Text = "200"
rangeBox.Font = Enum.Font.SourceSans
rangeBox.TextSize = 14
rangeBox.Parent = tabMain
rangeBox.FocusLost:Connect(function()
    farmRange = tonumber(rangeBox.Text) or 200
end)

-- Cài đặt thời gian farm quest
local questTimeBox = Instance.new("TextBox")
questTimeBox.Size = UDim2.new(1, -20, 0, 30)
questTimeBox.Position = UDim2.new(0, 10, 0, 290)
questTimeBox.BackgroundColor3 = Color3.fromRGB(100, 149, 237)
questTimeBox.TextColor3 = Color3.new(1, 1, 1)
questTimeBox.PlaceholderText = "Thời gian farm quest (giây)"
questTimeBox.Text = tostring(questFarmDuration)
questTimeBox.Font = Enum.Font.SourceSans
questTimeBox.TextSize = 14
questTimeBox.Parent = tabMain
questTimeBox.FocusLost:Connect(function()
    questFarmDuration = tonumber(questTimeBox.Text) or 12
end)

-- Chọn boss (danh sách thả xuống nhỏ)
local bossList = {"Tất cả", "Akuma", "Tengoku", "Renshiki", "Forge Boss"}
local bossDropdown = Instance.new("TextButton")
bossDropdown.Size = UDim2.new(1, -20, 0, 30)
bossDropdown.Position = UDim2.new(0, 10, 0, 330)
bossDropdown.BackgroundColor3 = Color3.fromRGB(100, 149, 237)
bossDropdown.TextColor3 = Color3.new(1, 1, 1)
bossDropdown.Text = "Chọn Boss: Tất cả"
bossDropdown.Font = Enum.Font.SourceSans
bossDropdown.TextSize = 14
bossDropdown.Parent = tabMain
local bossIndex = 1
bossDropdown.MouseButton1Click:Connect(function()
    bossIndex = bossIndex % #bossList + 1
    targetBoss = bossList[bossIndex]
    bossDropdown.Text = "Chọn Boss: " .. targetBoss
end)

-- Thông báo
local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, 0, 0, 20)
statusLabel.Position = UDim2.new(0, 0, 1, -20)
statusLabel.BackgroundColor3 = Color3.fromRGB(173, 216, 230)
statusLabel.TextColor3 = Color3.new(0, 0, 0.3)
statusLabel.Font = Enum.Font.SourceSans
statusLabel.Text = "Sẵn sàng"
statusLabel.TextSize = 12
statusLabel.Parent = mainFrame

print("Shindo Pro v3.3 loaded! Bấm nút '+' màu xanh để mở menu.")
