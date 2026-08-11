--[[
    SHINDO LIFE PRO MOBILE v3.1 – Giao diện xanh biển nhạt, sửa lỗi toggle
    Yêu cầu: Delta X Mobile, hỗ trợ getgc, fireserver, fireclickdetector, v.v.
    Chức năng: Auto Farm, Auto Boss, Auto Quest, Auto Rank Up, Auto Scroll, Fly, Noclip.
]]

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInputManager = game:GetService("VirtualInputManager")

-- Tìm Remote
local function findRemote(name)
    for _, v in pairs(ReplicatedStorage:GetDescendants()) do
        if v:IsA("RemoteEvent") and v.Name == name then return v end
    end
    return nil
end
local damageRemote = findRemote("Damage") or findRemote("CastSpell") or findRemote("Attack")
local questStartRemote = findRemote("StartQuest") or findRemote("AcceptQuest")
local questFinishRemote = findRemote("CompleteQuest") or findRemote("FinishQuest")
local rankUpRemote = findRemote("RankUp") or findRemote("Promote")
local equipRemote = findRemote("EquipSkill") or findRemote("SelectSkill")

-- Biến trạng thái
local flyEnabled, noclipEnabled, autoFarmEnabled, autoBossEnabled, autoQuestEnabled, autoRankEnabled, autoScrollEnabled = false, false, false, false, false, false, false
local spamSkill = true
local farmRange = 150
local targetBoss = "Tất cả"
local flySpeed = 50
local bodyVel, bodyGyro

-- Hàm hỗ trợ
local function teleportToCFrame(cf)
    local c = LocalPlayer.Character
    if c and c:FindFirstChild("HumanoidRootPart") then
        if noclipEnabled then c.HumanoidRootPart.CFrame = cf
        else TweenService:Create(c.HumanoidRootPart, TweenInfo.new(0.3), {CFrame = cf}):Play() end
    end
end

local function findNearestEnemy(range, specificName)
    local c = LocalPlayer.Character
    if not c then return nil end
    local hrp = c:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end
    local nearest, minDist = nil, range or 150
    for _, o in pairs(Workspace:GetDescendants()) do
        if o:IsA("Model") and o ~= c then
            local hum = o:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then
                local root = o:FindFirstChild("HumanoidRootPart")
                if root then
                    if specificName and not o.Name:lower():find(specificName:lower()) then
                        -- skip
                    else
                        local dist = (hrp.Position - root.Position).Magnitude
                        if dist < minDist then minDist = dist; nearest = o end
                    end
                end
            end
        end
    end
    return nearest
end

local function findBoss(name)
    for _, o in pairs(Workspace:GetDescendants()) do
        if o:IsA("Model") and o.Name:lower():find("boss") then
            local hum = o:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then
                if name == "Tất cả" then return o
                elseif o.Name:lower():find(name:lower()) then return o end
            end
        end
    end
    return nil
end

local function findQuestNPC()
    for _, o in pairs(Workspace:GetDescendants()) do
        if o:IsA("Model") then
            if o.Name:lower():find("quest") or o.Name:lower():find("npc") then
                local hum = o:FindFirstChildOfClass("Humanoid")
                if hum and hum.Health > 0 then return o end
            end
            local head = o:FindFirstChild("Head")
            if head then
                local bill = head:FindFirstChildOfClass("BillboardGui")
                if bill and bill.TextLabel and bill.TextLabel.Text == "!" then return o end
            end
        end
    end
    return nil
end

local function findScroll()
    for _, o in pairs(Workspace:GetDescendants()) do
        if o:IsA("Model") and (o.Name:lower():find("scroll") or o.Name:lower():find("paper")) then return o end
    end
    return nil
end

local function attackTarget(target)
    if damageRemote then pcall(function() damageRemote:FireServer(target, "Skill1") end)
    else
        local pos, onScreen = Workspace.CurrentCamera:WorldToViewportPoint(target:FindFirstChild("HumanoidRootPart").Position)
        if onScreen then
            VirtualInputManager:SendMouseButtonEvent(pos.X, pos.Y, 0, true, game, 1)
            task.wait(0.05)
            VirtualInputManager:SendMouseButtonEvent(pos.X, pos.Y, 0, false, game, 1)
        end
    end
end

-- Chức năng Fly
function toggleFly()
    flyEnabled = not flyEnabled
    local c = LocalPlayer.Character
    if not c then return end
    local hrp = c:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    if flyEnabled then
        bodyVel = Instance.new("BodyVelocity")
        bodyVel.MaxForce = Vector3.new(1,1,1) * math.huge
        bodyVel.Velocity = Vector3.new(0,0,0)
        bodyVel.Parent = hrp
        bodyGyro = Instance.new("BodyGyro")
        bodyGyro.MaxTorque = Vector3.new(1,1,1) * math.huge
        bodyGyro.CFrame = hrp.CFrame
        bodyGyro.Parent = hrp
        if joystickFrame then joystickFrame.Visible = true end
    else
        if bodyVel then bodyVel:Destroy() end
        if bodyGyro then bodyGyro:Destroy() end
        if joystickFrame then joystickFrame.Visible = false end
    end
end

-- Noclip
function toggleNoclip()
    noclipEnabled = not noclipEnabled
    local c = LocalPlayer.Character
    if c then
        for _, p in pairs(c:GetDescendants()) do
            if p:IsA("BasePart") then p.CanCollide = not noclipEnabled end
        end
    end
end

-- Auto Farm
local farmThread
function toggleAutoFarm()
    autoFarmEnabled = not autoFarmEnabled
    if autoFarmEnabled then
        farmThread = task.spawn(function()
            while autoFarmEnabled do
                if not autoQuestEnabled then
                    local target = findNearestEnemy(farmRange)
                    if target then teleportToCFrame(target.HumanoidRootPart.CFrame + Vector3.new(0,3,0)); attackTarget(target) end
                end
                task.wait(0.1)
            end
        end)
    else if farmThread then task.cancel(farmThread) end end
end

-- Auto Boss
local bossThread
function toggleAutoBoss()
    autoBossEnabled = not autoBossEnabled
    if autoBossEnabled then
        bossThread = task.spawn(function()
            while autoBossEnabled do
                local boss = findBoss(targetBoss)
                if boss then
                    teleportToCFrame(boss.HumanoidRootPart.CFrame + Vector3.new(0,5,0))
                    if damageRemote then pcall(function() damageRemote:FireServer(boss, "Ultimate") end)
                    else attackTarget(boss) end
                end
                task.wait(0.2)
            end
        end)
    else if bossThread then task.cancel(bossThread) end end
end

-- Auto Quest
local questThread
function toggleAutoQuest()
    autoQuestEnabled = not autoQuestEnabled
    if autoQuestEnabled then
        questThread = task.spawn(function()
            while autoQuestEnabled do
                local npc = findQuestNPC()
                if npc then
                    teleportToCFrame(npc.HumanoidRootPart.CFrame + Vector3.new(0,3,5))
                    task.wait(0.5)
                    if questStartRemote then pcall(function() questStartRemote:FireServer() end)
                    else
                        local pos = Workspace.CurrentCamera:WorldToViewportPoint(npc.Head.Position)
                        VirtualInputManager:SendMouseButtonEvent(pos.X, pos.Y, 0, true, game, 1)
                        task.wait(0.1)
                        VirtualInputManager:SendMouseButtonEvent(pos.X, pos.Y, 0, false, game, 1)
                    end
                    task.wait(1)
                    local startTime = tick()
                    while tick() - startTime < 8 and autoQuestEnabled do
                        local enemy = findNearestEnemy(100)
                        if enemy then teleportToCFrame(enemy.HumanoidRootPart.CFrame + Vector3.new(0,3,0)); attackTarget(enemy) end
                        task.wait(0.2)
                    end
                    teleportToCFrame(npc.HumanoidRootPart.CFrame + Vector3.new(0,3,5))
                    task.wait(0.5)
                    if questFinishRemote then pcall(function() questFinishRemote:FireServer() end)
                    else
                        local pos = Workspace.CurrentCamera:WorldToViewportPoint(npc.Head.Position)
                        VirtualInputManager:SendMouseButtonEvent(pos.X, pos.Y, 0, true, game, 1)
                        task.wait(0.1)
                        VirtualInputManager:SendMouseButtonEvent(pos.X, pos.Y, 0, false, game, 1)
                    end
                    task.wait(2)
                else task.wait(2) end
            end
        end)
    else if questThread then task.cancel(questThread) end end
end

-- Auto Rank Up
local rankThread
function toggleAutoRank()
    autoRankEnabled = not autoRankEnabled
    if autoRankEnabled then
        rankThread = task.spawn(function()
            while autoRankEnabled do
                if rankUpRemote then pcall(function() rankUpRemote:FireServer() end)
                else
                    local gui = LocalPlayer.PlayerGui:FindFirstChild("RankUpButton") or LocalPlayer.PlayerGui:FindFirstChild("RankUp")
                    if gui and gui:IsA("TextButton") then
                        local pos = gui.AbsolutePosition + gui.AbsoluteSize/2
                        VirtualInputManager:SendMouseButtonEvent(pos.X, pos.Y, 0, true, game, 1)
                        task.wait(0.1)
                        VirtualInputManager:SendMouseButtonEvent(pos.X, pos.Y, 0, false, game, 1)
                    end
                end
                task.wait(10)
            end
        end)
    else if rankThread then task.cancel(rankThread) end end
end

-- Auto Scroll
local scrollThread
function toggleAutoScroll()
    autoScrollEnabled = not autoScrollEnabled
    if autoScrollEnabled then
        scrollThread = task.spawn(function()
            while autoScrollEnabled do
                local s = findScroll()
                if s and s:FindFirstChild("Part") then teleportToCFrame(s.Part.CFrame) end
                task.wait(0.5)
            end
        end)
    else if scrollThread then task.cancel(scrollThread) end end
end

-- ================== GIAO DIỆN MÀU XANH BIỂN NHẠT ==================
local mainGui = Instance.new("ScreenGui")
mainGui.Name = "ShindoPro"
mainGui.ResetOnSpawn = false
mainGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

-- Nút Toggle (màu xanh biển nhạt)
local toggleBtn = Instance.new("TextButton")
toggleBtn.Size = UDim2.new(0, 70, 0, 70)
toggleBtn.Position = UDim2.new(0, 10, 0.5, -35)
toggleBtn.BackgroundColor3 = Color3.fromRGB(135, 206, 235) -- xanh biển nhạt
toggleBtn.BackgroundTransparency = 0.2
toggleBtn.Text = "+"
toggleBtn.TextColor3 = Color3.new(1, 1, 1)
toggleBtn.TextSize = 36
toggleBtn.Font = Enum.Font.SourceSansBold
toggleBtn.ZIndex = 10
toggleBtn.Active = true
toggleBtn.Parent = mainGui
Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0, 12)

local guiVisible = false

-- Sửa lỗi không hiện: dùng cả MouseButton1Click và InputBegan
toggleBtn.MouseButton1Click:Connect(function()
    guiVisible = not guiVisible
    mainFrame.Visible = guiVisible
    toggleBtn.Text = guiVisible and "−" or "+"
end)
toggleBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch then
        guiVisible = not guiVisible
        mainFrame.Visible = guiVisible
        toggleBtn.Text = guiVisible and "−" or "+"
    end
end)

-- Khung chính (xanh nhạt)
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 300, 0, 400)
mainFrame.Position = UDim2.new(0, 10, 0.5, -200)
mainFrame.BackgroundColor3 = Color3.fromRGB(230, 240, 250) -- xanh biển nhạt
mainFrame.BorderSizePixel = 0
mainFrame.Visible = false
mainFrame.ClipsDescendants = true
mainFrame.Parent = mainGui
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 12)

-- Tiêu đề
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 30)
title.BackgroundColor3 = Color3.fromRGB(173, 216, 230) -- xanh đậm hơn
title.TextColor3 = Color3.new(0.1, 0.1, 0.3)
title.Font = Enum.Font.SourceSansBold
title.Text = "Shindo Pro v3.1"
title.TextSize = 16
title.Parent = mainFrame

local tabContainer = Instance.new("Frame")
tabContainer.Size = UDim2.new(1, 0, 1, -30)
tabContainer.Position = UDim2.new(0, 0, 0, 30)
tabContainer.BackgroundTransparency = 1
tabContainer.Parent = mainFrame

-- Tab Main duy nhất (cho đơn giản)
local tabMain = Instance.new("Frame")
tabMain.Size = UDim2.new(1, 0, 1, 0)
tabMain.BackgroundTransparency = 1
tabMain.Parent = tabContainer

-- Hàm thêm nút toggle (màu xanh nhạt đẹp)
local function addToggleButton(parent, text, y, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -20, 0, 35)
    btn.Position = UDim2.new(0, 10, 0, y)
    btn.BackgroundColor3 = Color3.fromRGB(100, 149, 237) -- xanh dương hoa ngô
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.Font = Enum.Font.SourceSans
    btn.Text = text .. ": OFF"
    btn.TextSize = 14
    btn.Parent = parent
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    local enabled = false
    btn.MouseButton1Click:Connect(function()
        enabled = not enabled
        btn.Text = text .. ": " .. (enabled and "ON" or "OFF")
        btn.BackgroundColor3 = enabled and Color3.fromRGB(0, 128, 0) or Color3.fromRGB(100, 149, 237)
        callback(enabled)
    end)
    return btn
end

-- Các nút
addToggleButton(tabMain, "Bay (Fly)", 10, function(on) toggleFly() end)
addToggleButton(tabMain, "Xuyên Tường", 50, function(on) toggleNoclip() end)
addToggleButton(tabMain, "Auto Farm", 90, function(on) toggleAutoFarm() end)
addToggleButton(tabMain, "Auto Boss", 130, function(on) toggleAutoBoss() end)
addToggleButton(tabMain, "Auto Quest", 170, function(on) toggleAutoQuest() end)
addToggleButton(tabMain, "Auto Rank Up", 210, function(on) toggleAutoRank() end)
addToggleButton(tabMain, "Auto Scroll", 250, function(on) toggleAutoScroll() end)

-- Joystick bay (hiển thị khi bật bay)
local joystickFrame = Instance.new("Frame")
joystickFrame.Size = UDim2.new(0, 120, 0, 120)
joystickFrame.Position = UDim2.new(0, 30, 0.8, 0)
joystickFrame.BackgroundColor3 = Color3.fromRGB(135, 206, 235)
joystickFrame.BackgroundTransparency = 0.5
joystickFrame.BorderSizePixel = 0
joystickFrame.Visible = false
joystickFrame.Parent = mainGui
local joyBtn = Instance.new("ImageButton")
joyBtn.Size = UDim2.new(0, 50, 0, 50)
joyBtn.Position = UDim2.new(0.5, -25, 0.5, -25)
joyBtn.BackgroundColor3 = Color3.new(1, 1, 1)
joyBtn.BackgroundTransparency = 0.5
joyBtn.Image = "rbxassetid://0"
joyBtn.Parent = joystickFrame
local joystickActive = false
joyBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch then joystickActive = true end
end)
joyBtn.InputChanged:Connect(function(input)
    if joystickActive and input.UserInputType == Enum.UserInputType.Touch then
        local delta = input.Position - joyBtn.AbsolutePosition - joyBtn.AbsoluteSize / 2
        if bodyVel then
            bodyVel.Velocity = Vector3.new(delta.X, 0, delta.Y) * (flySpeed / 50) + Vector3.new(0, delta.Y > 0 and flySpeed/2 or -flySpeed/2, 0)
        end
    end
end)
joyBtn.InputEnded:Connect(function()
    joystickActive = false
    if bodyVel then bodyVel.Velocity = Vector3.new() end
end)

-- Cập nhật hiển thị joystick khi toggle fly
local oldToggleFly = toggleFly
toggleFly = function()
    oldToggleFly()
    joystickFrame.Visible = flyEnabled
end

print("Shindo Pro v3.1 (xanh biển nhạt) đã sẵn sàng. Bấm '+' để mở menu.")
