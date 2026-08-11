-- Script Hack Shindo Life Mobile (Delta X) – Đã sửa lỗi nút Toggle không hiển thị GUI
-- Lỗi cũ: nút "+" bấm không mở được bảng điều khiển do thiếu Active, kích thước quá nhỏ,
-- hoặc sự kiện MouseButton1Click không kích hoạt trên một số thiết bị cảm ứng.
-- Sửa: tăng kích thước nút, thêm Active, thay bằng InputBegan để bắt cả chạm và chuột.

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Tìm Remote (nếu không có, auto farm sẽ dùng VirtualUser)
local function findRemote(name)
    for _, v in pairs(ReplicatedStorage:GetDescendants()) do
        if v:IsA("RemoteEvent") and v.Name == name then return v end
    end
    return nil
end
local damageRemote = findRemote("Damage") or findRemote("CastSpell") or findRemote("Attack")

-- Hàm phụ trợ
local function findNearestEnemy(range)
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
                    local dist = (hrp.Position - root.Position).Magnitude
                    if dist < minDist then
                        minDist = dist
                        nearest = o
                    end
                end
            end
        end
    end
    return nearest
end

local function teleportToCFrame(cf)
    local c = LocalPlayer.Character
    if c and c:FindFirstChild("HumanoidRootPart") then
        c.HumanoidRootPart.CFrame = cf
    end
end

-- Biến trạng thái
local flyEnabled = false
local noclipEnabled = false
local autoFarmEnabled = false
local autoBossEnabled = false
local autoScrollEnabled = false
local spamSkill = true
local farmRange = 150
local targetBoss = "Tất cả"
local flySpeed = 50
local bodyVel, bodyGyro

-- Chức năng Fly (đơn giản, dùng BodyVelocity)
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
        -- Hiển thị joystick nếu có
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
            if p:IsA("BasePart") then
                p.CanCollide = not noclipEnabled
            end
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
                local target = findNearestEnemy(farmRange)
                if target and target:FindFirstChild("HumanoidRootPart") then
                    teleportToCFrame(target.HumanoidRootPart.CFrame + Vector3.new(0,3,0))
                    if spamSkill and damageRemote then
                        pcall(function()
                            damageRemote:FireServer(target, "Skill1")
                        end)
                    end
                end
                task.wait(0.1)
            end
        end)
    else
        if farmThread then task.cancel(farmThread) end
    end
end

-- Auto Boss
local bossThread
local function findBoss()
    for _, o in pairs(Workspace:GetDescendants()) do
        if o:IsA("Model") and o.Name:lower():find("boss") then
            local hum = o:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then
                if targetBoss == "Tất cả" then return o
                elseif o.Name:lower():find(targetBoss:lower()) then return o
                end
            end
        end
    end
    return nil
end
function toggleAutoBoss()
    autoBossEnabled = not autoBossEnabled
    if autoBossEnabled then
        bossThread = task.spawn(function()
            while autoBossEnabled do
                local boss = findBoss()
                if boss and boss:FindFirstChild("HumanoidRootPart") then
                    teleportToCFrame(boss.HumanoidRootPart.CFrame + Vector3.new(0,5,0))
                    if spamSkill and damageRemote then
                        pcall(function()
                            damageRemote:FireServer(boss, "Ultimate")
                        end)
                    end
                end
                task.wait(0.2)
            end
        end)
    else
        if bossThread then task.cancel(bossThread) end
    end
end

-- Auto Scroll
local scrollThread
local function findScroll()
    for _, o in pairs(Workspace:GetDescendants()) do
        if o:IsA("Model") and (o.Name:lower():find("scroll") or o.Name:lower():find("paper")) then
            return o
        end
    end
    return nil
end
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
local guiVisible = false
local mainGui = Instance.new("ScreenGui")
mainGui.Name = "ShindoPro"
mainGui.ResetOnSpawn = false
mainGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

-- Nút Toggle to, dễ bấm, sử dụng InputBegan
local toggleBtn = Instance.new("TextButton")
toggleBtn.Size = UDim2.new(0, 70, 0, 70)   -- tăng kích thước cho dễ chạm
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
Instance.new("UIStroke", mainFrame).Color = Color3.fromRGB(100, 0, 100)

-- Tiêu đề
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 35)
title.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
title.TextColor3 = Color3.new(1, 1, 1)
title.Font = Enum.Font.SourceSansBold
title.Text = "Shindo Pro v2.1 (Fixed)"
title.TextSize = 16
title.Parent = mainFrame
Instance.new("UICorner", title).CornerRadius = UDim.new(0, 8)

-- Tạo tab
local tabContainer = Instance.new("Frame")
tabContainer.Size = UDim2.new(1, 0, 1, -35)
tabContainer.Position = UDim2.new(0, 0, 0, 35)
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
local tabFarm = addTab("Farm")
local tabBoss = addTab("Boss")
local tabScroll = addTab("Scroll")
local tabTele = addTab("Tele")
local tabSet = addTab("Set")

-- Nút tab
local tabNames = {"Main", "Farm", "Boss", "Scroll", "Tele", "Set"}
for i, name in ipairs(tabNames) do
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1 / 6, 0, 0, 25)
    btn.Position = UDim2.new((i - 1) / 6, 0, 0, 0)
    btn.BackgroundColor3 = Color3.new(0.3, 0.3, 0.3)
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.Font = Enum.Font.SourceSans
    btn.Text = name
    btn.TextSize = 14
    btn.Parent = title
    btn.MouseButton1Click:Connect(function()
        for _, t in pairs(tabs) do t.Visible = false end
        if tabs[name] then tabs[name].Visible = true end
    end)
end
tabs["Main"].Visible = true

-- Hàm thêm nút chức năng
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

-- Tab Main: bật/tắt các tính năng
addToggleButton(tabMain, "Bay", 10, function(on) toggleFly() end)
addToggleButton(tabMain, "Xuyên Tường", 50, function(on) toggleNoclip() end)
addToggleButton(tabMain, "Auto Farm", 90, function(on) toggleAutoFarm() end)
addToggleButton(tabMain, "Auto Boss", 130, function(on) toggleAutoBoss() end)
addToggleButton(tabMain, "Auto Scroll", 170, function(on) toggleAutoScroll() end)

-- Tab Farm: Spam Skill, Phạm vi
local spamBtn = addToggleButton(tabFarm, "Spam Skill", 10, function(on) spamSkill = on end)
spamBtn.Text = "Spam Skill: ON"
spamBtn.BackgroundColor3 = Color3.new(0.2, 0.8, 0.2)

local rangeBox = Instance.new("TextBox")
rangeBox.Size = UDim2.new(1, -20, 0, 30)
rangeBox.Position = UDim2.new(0, 10, 0, 50)
rangeBox.BackgroundColor3 = Color3.new(0.3, 0.3, 0.3)
rangeBox.TextColor3 = Color3.new(1, 1, 1)
rangeBox.PlaceholderText = "Phạm vi (mặc định 150)"
rangeBox.Text = "150"
rangeBox.Parent = tabFarm
rangeBox.FocusLost:Connect(function()
    farmRange = tonumber(rangeBox.Text) or 150
end)

-- Tab Boss
local bossNames = {"Tất cả", "Akuma", "Tengoku", "Renshiki", "Forge Boss"}
for i, name in ipairs(bossNames) do
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -20, 0, 30)
    btn.Position = UDim2.new(0, 10, 0, 10 + (i-1)*35)
    btn.BackgroundColor3 = Color3.new(0.4, 0.4, 0.4)
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.Text = name
    btn.Parent = tabBoss
    btn.MouseButton1Click:Connect(function()
        targetBoss = name
    end)
end

-- Tab Scroll
local refreshBtn = Instance.new("TextButton")
refreshBtn.Size = UDim2.new(1, -20, 0, 30)
refreshBtn.Position = UDim2.new(0, 10, 0, 10)
refreshBtn.BackgroundColor3 = Color3.new(0.4, 0.4, 0.4)
refreshBtn.TextColor3 = Color3.new(1, 1, 1)
refreshBtn.Text = "Làm mới danh sách Scroll"
refreshBtn.Parent = tabScroll
local scrollListFrame = Instance.new("ScrollingFrame")
scrollListFrame.Size = UDim2.new(1, -20, 1, -50)
scrollListFrame.Position = UDim2.new(0, 10, 0, 50)
scrollListFrame.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
scrollListFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
scrollListFrame.Parent = tabScroll
refreshBtn.MouseButton1Click:Connect(function()
    -- Làm mới danh sách scroll
    local scrolls = {}
    for _, o in pairs(Workspace:GetDescendants()) do
        if o:IsA("Model") and (o.Name:lower():find("scroll") or o.Name:lower():find("paper")) then
            table.insert(scrolls, o)
        end
    end
    -- Xóa nút cũ
    for _, v in pairs(scrollListFrame:GetChildren()) do
        if v:IsA("TextButton") then v:Destroy() end
    end
    for i, s in ipairs(scrolls) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, 0, 0, 25)
        btn.Position = UDim2.new(0, 0, 0, (i-1)*25)
        btn.Text = s.Name
        btn.BackgroundColor3 = Color3.new(0.3, 0.3, 0.3)
        btn.TextColor3 = Color3.new(1, 1, 1)
        btn.Parent = scrollListFrame
        btn.MouseButton1Click:Connect(function()
            if s:FindFirstChild("Part") then
                teleportToCFrame(s.Part.CFrame)
            end
        end)
    end
    scrollListFrame.CanvasSize = UDim2.new(0, 0, 0, #scrolls * 25)
end)

-- Tab Teleport
local teleportLocations = {
    ["Làng Lá"] = CFrame.new(-300, 10, 200),
    ["Làng Cát"] = CFrame.new(800, 10, -400),
    ["Làng Sương Mù"] = CFrame.new(200, 10, 900),
    ["Thác Nước"] = CFrame.new(0, 50, -800),
    ["Rừng Chết"] = CFrame.new(-700, 10, -300)
}
local teleFrame = Instance.new("ScrollingFrame")
teleFrame.Size = UDim2.new(1, -20, 1, -10)
teleFrame.Position = UDim2.new(0, 10, 0, 10)
teleFrame.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
teleFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
teleFrame.Parent = tabTele
local idx = 0
for name, cf in pairs(teleportLocations) do
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 25)
    btn.Position = UDim2.new(0, 0, 0, idx * 25)
    btn.Text = name
    btn.BackgroundColor3 = Color3.new(0.3, 0.3, 0.3)
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.Parent = teleFrame
    btn.MouseButton1Click:Connect(function()
        teleportToCFrame(cf)
    end)
    idx = idx + 1
end
teleFrame.CanvasSize = UDim2.new(0, 0, 0, idx * 25)

-- Tab Settings
local speedBox = Instance.new("TextBox")
speedBox.Size = UDim2.new(1, -20, 0, 30)
speedBox.Position = UDim2.new(0, 10, 0, 10)
speedBox.BackgroundColor3 = Color3.new(0.3, 0.3, 0.3)
speedBox.TextColor3 = Color3.new(1, 1, 1)
speedBox.PlaceholderText = "Tốc độ bay (50)"
speedBox.Text = "50"
speedBox.Parent = tabSet
speedBox.FocusLost:Connect(function()
    flySpeed = tonumber(speedBox.Text) or 50
end)

-- Joystick di động (hiện khi bật fly)
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
            bodyVel.Velocity = Vector3.new(delta.X, 0, delta.Y) * (flySpeed / 50) +
                              Vector3.new(0, delta.Y > 0 and flySpeed/2 or -flySpeed/2, 0)
        end
    end
end)
joyBtn.InputEnded:Connect(function()
    joystickActive = false
    if bodyVel then bodyVel.Velocity = Vector3.new() end
end)

-- ================== XỬ LÝ NÚT TOGGLE CHÍNH ==================
-- Sử dụng InputBegan để bắt tất cả loại nhấn (chuột, cảm ứng)
toggleBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or
       input.UserInputType == Enum.UserInputType.Touch then
        guiVisible = not guiVisible
        mainFrame.Visible = guiVisible
        toggleBtn.Text = guiVisible and "−" or "+"
    end
end)

print("Shindo Pro Fixed: Nhấn nút '+' để mở menu. Đã sẵn sàng!")
