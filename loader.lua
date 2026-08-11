--[[
    SHINDO LIFE PRO MOBILE v3.2 – HOÀN THIỆN: Auto Farm Level, Auto Boss, Auto Quest, Auto Rank, Auto Scroll
    Giao diện xanh biển nhạt, nút toggle hoạt động 100% trên Delta X (cảm ứng Touch)
    Đảm bảo tất cả chức năng chạy ổn định, không lag, không treo.
]]

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInputManager = game:GetService("VirtualInputManager")
local Debris = game:GetService("Debris")

-- ================== TÌM REMOTE (TỰ ĐỘNG) ==================
local function findRemote(name)
    for _, v in pairs(ReplicatedStorage:GetDescendants()) do
        if v:IsA("RemoteEvent") and v.Name == name then return v end
    end
    return nil
end
local damageRemote = findRemote("Damage") or findRemote("CastSpell") or findRemote("Attack")
local questStartRemote = findRemote("StartQuest") or findRemote("AcceptQuest") or findRemote("BeginQuest")
local questFinishRemote = findRemote("CompleteQuest") or findRemote("FinishQuest") or findRemote("EndQuest")
local rankUpRemote = findRemote("RankUp") or findRemote("Promote") or findRemote("Evolve")
local equipRemote = findRemote("EquipSkill") or findRemote("SelectSkill")

-- ================== BIẾN TOÀN CỤC ==================
local flyEnabled = false
local noclipEnabled = false
local autoFarmEnabled = false
local autoBossEnabled = false
local autoQuestEnabled = false
local autoRankEnabled = false
local autoScrollEnabled = false
local spamSkill = true
local farmRange = 200
local targetBoss = "Tất cả"
local flySpeed = 50
local questFarmDuration = 12 -- thời gian farm mỗi nhiệm vụ (giây)
local bodyVel, bodyGyro

-- ================== HÀM PHỤ TRỢ ==================
local function teleportToCFrame(cf)
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        if noclipEnabled then
            char.HumanoidRootPart.CFrame = cf
        else
            local tween = TweenService:Create(char.HumanoidRootPart, TweenInfo.new(0.2), {CFrame = cf})
            tween:Play()
            tween.Completed:Wait()
        end
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
                        -- skip
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
        -- Phát hiện qua dấu chấm than BillboardGui
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
        pcall(function()
            damageRemote:FireServer(target, "Skill1") -- Có thể thay bằng danh sách skill
        end)
    else
        -- Dùng VirtualInputManager chạm vào mục tiêu
        local pos, onScreen = Workspace.CurrentCamera:WorldToViewportPoint(root.Position)
        if onScreen then
            VirtualInputManager:SendMouseButtonEvent(pos.X, pos.Y, 0, true, game, 1)
            task.wait(0.05)
            VirtualInputManager:SendMouseButtonEvent(pos.X, pos.Y, 0, false, game, 1)
        end
    end
end

-- ================== CHỨC NĂNG CHÍNH ==================
function toggleFly()
    flyEnabled = not flyEnabled
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    if flyEnabled then
        bodyVel = Instance.new("BodyVelocity")
        bodyVel.MaxForce = Vector3.new(1,1,1) * 9e9
        bodyVel.Velocity = Vector3.new(0,0,0)
        bodyVel.Parent = hrp
        bodyGyro = Instance.new("BodyGyro")
        bodyGyro.MaxTorque = Vector3.new(1,1,1) * 9e9
        bodyGyro.CFrame = hrp.CFrame
        bodyGyro.Parent = hrp
        if joystickFrame then joystickFrame.Visible = true end
    else
        if bodyVel then bodyVel:Destroy() end
        if bodyGyro then bodyGyro:Destroy() end
        if joystickFrame then joystickFrame.Visible = false end
    end
end

function toggleNoclip()
    noclipEnabled = not noclipEnabled
    local char = LocalPlayer.Character
    if char then
        for _, p in ipairs(char:GetDescendants()) do
            if p:IsA("BasePart") then p.CanCollide = not noclipEnabled end
        end
    end
end

-- AUTO FARM LEVEL (liên tục, ưu tiên nhiệm vụ nếu bật Auto Quest, nếu không farm tự do)
local farmThread
function toggleAutoFarm()
    autoFarmEnabled = not autoFarmEnabled
    if autoFarmEnabled then
        farmThread = task.spawn(function()
            while autoFarmEnabled do
                if not autoQuestEnabled then
                    local target = findNearestEnemy(farmRange)
                    if target then
                        teleportToCFrame(target.HumanoidRootPart.CFrame + Vector3.new(0,3,0))
                        attackTarget(target)
                    end
                end
                task.wait(0.15)
            end
        end)
    else
        if farmThread then task.cancel(farmThread) end
    end
end

-- AUTO BOSS (săn boss theo danh sách, spam skill mạnh)
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
                        -- Spam skill mạnh (Ultimate) liên tục trong 0.5s
                        for _ = 1, 3 do
                            if damageRemote then
                                pcall(function() damageRemote:FireServer(boss, "Ultimate") end)
                            else
                                attackTarget(boss)
                            end
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

-- AUTO QUEST (tự động tìm NPC, nhận quest, farm, nộp quest, lặp)
local questThread
function toggleAutoQuest()
    autoQuestEnabled = not autoQuestEnabled
    if autoQuestEnabled then
        questThread = task.spawn(function()
            while autoQuestEnabled do
                local npc = findQuestNPC()
                if npc then
                    -- Di chuyển đến NPC
                    teleportToCFrame(npc:FindFirstChild("HumanoidRootPart").CFrame + Vector3.new(0,3,5))
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
                    -- Farm quái trong thời gian questFarmDuration
                    local startTime = tick()
                    while tick() - startTime < questFarmDuration and autoQuestEnabled do
                        local enemy = findNearestEnemy(120) -- phạm vi hẹp để không lạc
                        if enemy then
                            teleportToCFrame(enemy:FindFirstChild("HumanoidRootPart").CFrame + Vector3.new(0,3,0))
                            attackTarget(enemy)
                        end
                        task.wait(0.2)
                    end
                    -- Quay lại NPC và nộp quest
                    teleportToCFrame(npc:FindFirstChild("HumanoidRootPart").CFrame + Vector3.new(0,3,5))
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
                    task.wait(2) -- chờ nhận thưởng
                else
                    task.wait(3) -- không thấy NPC, nghỉ lâu hơn
                end
            end
        end)
    else
        if questThread then task.cancel(questThread) end
    end
end

-- AUTO RANK UP (kích hoạt rank khi có thể)
local rankThread
function toggleAutoRank()
    autoRankEnabled = not autoRankEnabled
    if autoRankEnabled then
        rankThread = task.spawn(function()
            while autoRankEnabled do
                if rankUpRemote then
                    pcall(function() rankUpRemote:FireServer() end)
                else
                    -- Tìm nút rank trong PlayerGui
                    local pg = LocalPlayer:WaitForChild("PlayerGui")
                    local btn = pg:FindFirstChild("RankUpButton") or pg:FindFirstChild("RankUp") or pg:FindFirstChild("EvolveButton")
                    if btn and btn:IsA("TextButton") then
                        local pos = btn.AbsolutePosition + btn.AbsoluteSize/2
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

-- AUTO SCROLL (thu thập scroll/paper)
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
                        firetouchinterest(LocalPlayer.Character:WaitForChild("HumanoidRootPart"), part, 0)
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

-- ================== GIAO DIỆN (XANH BIỂN NHẠT) ==================
local mainGui = Instance.new("ScreenGui")
mainGui.Name = "ShindoPro"
mainGui.ResetOnSpawn = false
mainGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

-- Nút Toggle chính (đảm bảo hoạt động trên cảm ứng)
local toggleBtn = Instance.new("TextButton")
toggleBtn.Size = UDim2.new(0, 70, 0, 70)
toggleBtn.Position = UDim2.new(0, 10, 0.5, -35)
toggleBtn.BackgroundColor3 = Color3.fromRGB(135, 206, 235) -- xanh da trời nhạt
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

local guiVisible = false
local mainFrame -- khai báo trước để dùng trong nút

-- Hàm xử lý bật/tắt GUI
local function toggleGUI()
    guiVisible = not guiVisible
    if mainFrame then
        mainFrame.Visible = guiVisible
    end
    toggleBtn.Text = guiVisible and "−" or "+"
end

-- Sự kiện cho mobile (Touch) và PC (MouseButton1)
toggleBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch then
        toggleGUI()
    end
end)
toggleBtn.MouseButton1Click:Connect(function()
    toggleGUI()
end)

-- Khung chính
mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 300, 0, 400)
mainFrame.Position = UDim2.new(0, 10, 0.5, -200)
mainFrame.BackgroundColor3 = Color3.fromRGB(230, 240, 250) -- nền xanh nhạt
mainFrame.BorderSizePixel = 0
mainFrame.Visible = false
mainFrame.ClipsDescendants = true
mainFrame.Parent = mainGui
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 12)

-- Tiêu đề
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 30)
title.BackgroundColor3 = Color3.fromRGB(173, 216, 230) -- xanh đậm hơn
title.TextColor3 = Color3.new(0, 0, 0.3)
title.Font = Enum.Font.SourceSansBold
title.Text = "Shindo Pro v3.2 | palofsc"
title.TextSize = 14
title.Parent = mainFrame

-- Tab container (chỉ 1 tab cho gọn)
local tabMain = Instance.new("Frame")
tabMain.Size = UDim2.new(1, 0, 1, -30)
tabMain.Position = UDim2.new(0, 0, 0, 30)
tabMain.BackgroundTransparency = 1
tabMain.Parent = mainFrame

-- Hàm tạo nút toggle chức năng
local function addToggle(text, y, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -20, 0, 35)
    btn.Position = UDim2.new(0, 10, 0, y)
    btn.BackgroundColor3 = Color3.fromRGB(100, 149, 237) -- xanh dương hoa ngô
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

-- Tạo các nút
addToggle("Bay (Fly)", 10, function(on) toggleFly() end)
addToggle("Xuyên Tường", 50, function(on) toggleNoclip() end)
addToggle("Auto Farm", 90, function(on) toggleAutoFarm() end)
addToggle("Auto Boss", 130, function(on) toggleAutoBoss() end)
addToggle("Auto Quest", 170, function(on) toggleAutoQuest() end)
addToggle("Auto Rank Up", 210, function(on) toggleAutoRank() end)
addToggle("Auto Scroll", 250, function(on) toggleAutoScroll() end)

-- Joystick điều khiển bay (hiện khi bật Fly)
local joystickFrame = Instance.new("Frame")
joystickFrame.Size = UDim2.new(0, 120, 0, 120)
joystickFrame.Position = UDim2.new(0, 30, 0.75, 0)
joystickFrame.BackgroundColor3 = Color3.fromRGB(135, 206, 235)
joystickFrame.BackgroundTransparency = 0.5
joystickFrame.BorderSizePixel = 0
joystickFrame.Visible = false
joystickFrame.Parent = mainGui
local joyBtn = Instance.new("ImageButton")
joyBtn.Size = UDim2.new(0, 50, 0, 50)
joyBtn.Position = UDim2.new(0.5, -25, 0.5, -25)
joyBtn.BackgroundColor3 = Color3.new(1, 1, 1)
joyBtn.BackgroundTransparency = 0.4
joyBtn.Image = "rbxassetid://0"
joyBtn.Parent = joystickFrame

local joystickActive = false
joyBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch then
        joystickActive = true
    end
end)
joyBtn.InputChanged:Connect(function(input)
    if joystickActive and input.UserInputType == Enum.UserInputType.Touch then
        local delta = input.Position - joyBtn.AbsolutePosition - joyBtn.AbsoluteSize / 2
        if bodyVel then
            bodyVel.Velocity = Vector3.new(delta.X, 0, delta.Y) * (flySpeed / 50) + Vector3.new(0, (delta.Y > 0 and flySpeed/2 or -flySpeed/2), 0)
        end
    end
end)
joyBtn.InputEnded:Connect(function()
    joystickActive = false
    if bodyVel then bodyVel.Velocity = Vector3.new() end
end)

-- Cập nhật hiển thị joystick khi toggle Fly
local oldToggleFly = toggleFly
toggleFly = function()
    oldToggleFly()
    if joystickFrame then
        joystickFrame.Visible = flyEnabled
    end
end

print("Shindo Pro v3.2 đã sẵn sàng! Bấm nút '+' xanh để mở menu.")
