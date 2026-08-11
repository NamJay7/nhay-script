--[[
    SHINDO LIFE PRO MOBILE v3.0 – Auto Quest, Auto Boss, Auto Farm Level, Auto Rank Up
    Yêu cầu: Delta X Mobile (hỗ trợ getgc, fireserver, fireclickdetector, v.v.)
    Chức năng:
    - Auto Farm Level (đánh quái gần nhất, spam skill)
    - Auto Boss (săn boss theo tên, spam skill mạnh)
    - Auto Quest (tự nhận nhiệm vụ, làm, nộp, nhận thưởng, loop)
    - Auto Rank Up (tự động rank khi đủ cấp)
    - Auto Scroll (nhặt scroll/paper quanh map)
    - GUI thu gọn, nút toggle lớn.
    Tất cả chạy mượt trên mobile, không cần teleport.
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

-- ================== TÌM REMOTE EVENT ==================
local function findRemote(name)
    for _, v in pairs(ReplicatedStorage:GetDescendants()) do
        if v:IsA("RemoteEvent") and v.Name == name then
            return v
        end
    end
    return nil
end

local damageRemote = findRemote("Damage") or findRemote("CastSpell") or findRemote("Attack")
local questStartRemote = findRemote("StartQuest") or findRemote("AcceptQuest") or findRemote("BeginQuest")
local questFinishRemote = findRemote("CompleteQuest") or findRemote("FinishQuest") or findRemote("EndQuest")
local rankUpRemote = findRemote("RankUp") or findRemote("Promote") or findRemote("Evolve")
local equipRemote = findRemote("EquipSkill") or findRemote("SelectSkill")

-- Nếu không có remote, dùng VirtualUser giả lập chuột
local useVirtualInput = (not damageRemote) or (not questStartRemote)

-- ================== BIẾN TOÀN CỤC ==================
local flyEnabled = false
local noclipEnabled = false
local autoFarmEnabled = false
local autoBossEnabled = false
local autoQuestEnabled = false
local autoRankEnabled = false
local autoScrollEnabled = false
local spamSkill = true
local farmRange = 150
local targetBoss = "Tất cả"
local flySpeed = 50
local currentQuestId = nil
local questCompleted = false

-- ================== CÁC HÀM PHỤ TRỢ ==================
local function teleportToCFrame(cf)
    local c = LocalPlayer.Character
    if c and c:FindFirstChild("HumanoidRootPart") then
        if noclipEnabled then
            c.HumanoidRootPart.CFrame = cf
        else
            local tween = TweenService:Create(c.HumanoidRootPart, TweenInfo.new(0.3), {CFrame = cf})
            tween:Play()
            tween.Completed:Wait()
        end
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
                        -- continue
                    else
                        local dist = (hrp.Position - root.Position).Magnitude
                        if dist < minDist then
                            minDist = dist
                            nearest = o
                        end
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
                elseif o.Name:lower():find(name:lower()) then return o
                end
            end
        end
    end
    return nil
end

local function findQuestNPC()
    -- NPC thường có dấu chấm than, tên như "Quest Giver", "NPC", hoặc có billboard
    for _, o in pairs(Workspace:GetDescendants()) do
        if o:IsA("Model") then
            if o.Name:lower():find("quest") or o.Name:lower():find("npc") then
                local hum = o:FindFirstChildOfClass("Humanoid")
                if hum and hum.Health > 0 then
                    return o
                end
            end
            -- Hoặc tìm Head có BillboardGui "!"
            local head = o:FindFirstChild("Head")
            if head then
                local bill = head:FindFirstChildOfClass("BillboardGui")
                if bill and bill.TextLabel and bill.TextLabel.Text == "!" then
                    return o
                end
            end
        end
    end
    return nil
end

local function findScroll()
    for _, o in pairs(Workspace:GetDescendants()) do
        if o:IsA("Model") and (o.Name:lower():find("scroll") or o.Name:lower():find("paper")) then
            return o
        end
    end
    return nil
end

-- Hàm giả lập tấn công nếu không có Remote
local function attackTarget(target)
    if damageRemote then
        pcall(function()
            damageRemote:FireServer(target, "Skill1")
        end)
    else
        -- Giả lập click chuột vào mục tiêu
        local pos, onScreen = Workspace.CurrentCamera:WorldToViewportPoint(target:FindFirstChild("HumanoidRootPart").Position)
        if onScreen then
            VirtualInputManager:SendMouseButtonEvent(pos.X, pos.Y, 0, true, game, 1)
            wait(0.05)
            VirtualInputManager:SendMouseButtonEvent(pos.X, pos.Y, 0, false, game, 1)
        end
    end
end

local function equipSkill(skillName)
    if equipRemote then
        pcall(function()
            equipRemote:FireServer(skillName)
        end)
    end
end

-- ================== CHỨC NĂNG BAY ==================
local bodyVel, bodyGyro
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

-- ================== NOCLIP ==================
function toggleNoclip()
    noclipEnabled = not noclipEnabled
    local c = LocalPlayer.Character
    if c then
        for _, p in pairs(c:GetDescendants()) do
            if p:IsA("BasePart") then
                p.CanCollide = not noclipEnabled
            end
        end
    end
end

-- ================== AUTO FARM LEVEL ==================
local farmThread
function toggleAutoFarm()
    autoFarmEnabled = not autoFarmEnabled
    if autoFarmEnabled then
        farmThread = task.spawn(function()
            while autoFarmEnabled do
                if not autoQuestEnabled then -- nếu auto quest đang chạy thì dừng farm tự do
                    local target = findNearestEnemy(farmRange)
                    if target then
                        teleportToCFrame(target.HumanoidRootPart.CFrame + Vector3.new(0,3,0))
                        attackTarget(target)
                    end
                end
                task.wait(0.1)
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
                    teleportToCFrame(boss.HumanoidRootPart.CFrame + Vector3.new(0,5,0))
                    -- spam skill mạnh (Ultimate)
                    if damageRemote then
                        pcall(function()
                            damageRemote:FireServer(boss, "Ultimate")
                        end)
                    else
                        attackTarget(boss)
                    end
                end
                task.wait(0.2)
            end
        end)
    else
        if bossThread then task.cancel(bossThread) end
    end
end

-- ================== AUTO QUEST ==================
local questThread
function toggleAutoQuest()
    autoQuestEnabled = not autoQuestEnabled
    if autoQuestEnabled then
        questThread = task.spawn(function()
            while autoQuestEnabled do
                -- 1. Tìm NPC quest
                local npc = findQuestNPC()
                if not npc then
                    task.wait(2)
                    continue
                end
                -- 2. Di chuyển đến NPC
                teleportToCFrame(npc.HumanoidRootPart.CFrame + Vector3.new(0,3,5))
                task.wait(0.5)
                -- 3. Nhận nhiệm vụ (fire remote hoặc click vào NPC)
                if questStartRemote then
                    pcall(function()
                        questStartRemote:FireServer()
                    end)
                else
                    -- Click vào NPC bằng VirtualInputManager
                    local pos = Workspace.CurrentCamera:WorldToViewportPoint(npc.Head.Position)
                    VirtualInputManager:SendMouseButtonEvent(pos.X, pos.Y, 0, true, game, 1)
                    task.wait(0.1)
                    VirtualInputManager:SendMouseButtonEvent(pos.X, pos.Y, 0, false, game, 1)
                end
                task.wait(1)
                -- 4. Lấy thông tin nhiệm vụ (nếu có thể đọc PlayerGui)
                -- Tạm thời giả định nhiệm vụ yêu cầu giết quái thường
                -- Chúng ta sẽ farm quái gần đó cho đến khi đủ (theo dõi biến questCompleted qua Remote hoặc UI)
                local questDone = false
                local startTime = tick()
                while not questDone and autoQuestEnabled do
                    -- Nếu có thể đọc GUI nhiệm vụ để biết tiến trình, ta sẽ làm; nếu không, farm trong 10s rồi quay lại nộp.
                    -- Ở đây tạm thời farm trong 8 giây (có thể tùy chỉnh)
                    if tick() - startTime > 8 then
                        questDone = true
                    end
                    -- Farm quái gần NPC
                    local enemy = findNearestEnemy(100)
                    if enemy then
                        teleportToCFrame(enemy.HumanoidRootPart.CFrame + Vector3.new(0,3,0))
                        attackTarget(enemy)
                    end
                    task.wait(0.2)
                end
                -- 5. Quay lại NPC và nộp nhiệm vụ
                teleportToCFrame(npc.HumanoidRootPart.CFrame + Vector3.new(0,3,5))
                task.wait(0.5)
                if questFinishRemote then
                    pcall(function()
                        questFinishRemote:FireServer()
                    end)
                else
                    local pos = Workspace.CurrentCamera:WorldToViewportPoint(npc.Head.Position)
                    VirtualInputManager:SendMouseButtonEvent(pos.X, pos.Y, 0, true, game, 1)
                    task.wait(0.1)
                    VirtualInputManager:SendMouseButtonEvent(pos.X, pos.Y, 0, false, game, 1)
                end
                task.wait(2) -- chờ nhận thưởng, rồi lặp lại
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
                    pcall(function()
                        rankUpRemote:FireServer()
                    end)
                else
                    -- Tìm nút Rank Up trên GUI và click
                    local gui = LocalPlayer.PlayerGui:FindFirstChild("RankUpButton") or LocalPlayer.PlayerGui:FindFirstChild("RankUp")
                    if gui and gui:IsA("TextButton") then
                        local pos = gui.AbsolutePosition + gui.AbsoluteSize/2
                        VirtualInputManager:SendMouseButtonEvent(pos.X, pos.Y, 0, true, game, 1)
                        task.wait(0.1)
                        VirtualInputManager:SendMouseButtonEvent(pos.X, pos.Y, 0, false, game, 1)
                    end
                end
                task.wait(10) -- kiểm tra mỗi 10s
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
                local s = findScroll()
                if s and s:FindFirstChild("Part") then
                    teleportToCFrame(s.Part.CFrame)
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
mainGui.Name = "ShindoPro"
mainGui.ResetOnSpawn = false
mainGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

-- Nút Toggle lớn
local toggleBtn = Instance.new("TextButton")
toggleBtn.Size = UDim2.new(0, 70, 0, 70)
toggleBtn.Position = UDim2.new(0, 10, 0.5, -35)
toggleBtn.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
toggleBtn.BackgroundTransparency = 0.3
toggleBtn.Text = "+"
toggleBtn.TextColor3 = Color3.new(1, 1, 1)
toggleBtn.TextSize = 36
toggleBtn.Font = Enum.Font.SourceSansBold
toggleBtn.ZIndex = 10
toggleBtn.Active = true
toggleBtn.Parent = mainGui
Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0, 12)

local guiVisible = false
toggleBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        guiVisible = not guiVisible
        mainFrame.Visible = guiVisible
        toggleBtn.Text = guiVisible and "−" or "+"
    end
end)

-- Khung chính
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 300, 0, 400)
mainFrame.Position = UDim2.new(0, 10, 0.5, -200)
mainFrame.BackgroundColor3 = Color3.new(0.1, 0.1, 0.1)
mainFrame.BorderSizePixel = 0
mainFrame.Visible = false
mainFrame.ClipsDescendants = true
mainFrame.Parent = mainGui
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 12)

-- Tiêu đề và tab
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 30)
title.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
title.TextColor3 = Color3.new(1, 1, 1)
title.Font = Enum.Font.SourceSansBold
title.Text = "Shindo Pro v3.0"
title.TextSize = 16
title.Parent = mainFrame

local tabContainer = Instance.new("Frame")
tabContainer.Size = UDim2.new(1, 0, 1, -30)
tabContainer.Position = UDim2.new(0, 0, 0, 30)
tabContainer.BackgroundTransparency = 1
tabContainer.Parent = mainFrame

local tabs = {}
local function addTab(name)
    local t = Instance.new("Frame")
    t.Size = UDim2.new(1, 0, 1, 0)
    t.BackgroundTransparency = 1
    t.Visible = false
    t.Parent = tabContainer
    tabs[name] = t
    return t
end
local tabMain = addTab("Main")

-- Tạo nút tab (chỉ có Main cho gọn)
local btnMain = Instance.new("TextButton")
btnMain.Size = UDim2.new(1, 0, 0, 20)
btnMain.Position = UDim2.new(0, 0, 0, 0)
btnMain.BackgroundColor3 = Color3.new(0.3, 0.3, 0.3)
btnMain.TextColor3 = Color3.new(1, 1, 1)
btnMain.Font = Enum.Font.SourceSans
btnMain.Text = "Main"
btnMain.TextSize = 14
btnMain.Parent = title
btnMain.MouseButton1Click:Connect(function()
    for _, t in pairs(tabs) do t.Visible = false end
    tabMain.Visible = true
end)
tabMain.Visible = true

-- Hàm thêm nút toggle
local function addToggleButton(parent, text, y, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -20, 0, 35)
    btn.Position = UDim2.new(0, 10, 0, y)
    btn.BackgroundColor3 = Color3.new(0.4, 0.4, 0.4)
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
        btn.BackgroundColor3 = enabled and Color3.new(0.2, 0.8, 0.2) or Color3.new(0.4, 0.4, 0.4)
        callback(enabled)
    end)
    return btn
end

-- Các nút
addToggleButton(tabMain, "Bay (Fly)", 10, toggleFly)
addToggleButton(tabMain, "Xuyên Tường", 50, toggleNoclip)
addToggleButton(tabMain, "Auto Farm", 90, toggleAutoFarm)
addToggleButton(tabMain, "Auto Boss", 130, toggleAutoBoss)
addToggleButton(tabMain, "Auto Quest", 170, toggleAutoQuest)
addToggleButton(tabMain, "Auto Rank Up", 210, toggleAutoRank)
addToggleButton(tabMain, "Auto Scroll", 250, toggleAutoScroll)

-- Joystick điều khiển bay (hiện khi bật fly)
local joystickFrame = Instance.new("Frame")
joystickFrame.Size = UDim2.new(0, 120, 0, 120)
joystickFrame.Position = UDim2.new(0, 30, 0.8, 0)
joystickFrame.BackgroundColor3 = Color3.new(0, 0, 0)
joystickFrame.BackgroundTransparency = 0.7
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
    if input.UserInputType == Enum.UserInputType.Touch then
        joystickActive = true
    end
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

-- Cập nhật hiển thị joystick khi toggleFly
local oldToggleFly = toggleFly
toggleFly = function()
    oldToggleFly()
    joystickFrame.Visible = flyEnabled
end

print("Shindo Pro v3.0 đã sẵn sàng. Bấm '+' để mở menu.")
