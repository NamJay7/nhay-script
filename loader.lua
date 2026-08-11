--[[
    Script Hack Shindo Life Mobile (Delta X) – Siêu Tốc, Spam Skill, Farm Boss, Định Vị Scroll
    Yêu cầu: Delta X Mobile executor, hỗ trợ getgc, fireserver, firetouchinterest, v.v.
    Tối ưu cho màn hình cảm ứng, giao diện thu gọn, nhiều tính năng.
    Chạy một lần, giao diện chính sẽ ẩn/hiện qua nút tròn nhỏ.
]]

-- Dịch vụ
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui") or LocalPlayer:WaitForChild("PlayerGui")

-- Biến toàn cục
local guiVisible = true  -- hiển thị GUI chính
local mainGui = nil
local flyEnabled, noclipEnabled, autoFarmEnabled, autoBossEnabled, autoScrollEnabled = false, false, false, false, false
local flySpeed = 50
local farmRange = 150
local spamSkill = true
local selectedSkill = "All" -- hoặc tên skill cụ thể
local targetBoss = "Tất cả"
local scrollList = {}
local teleportLocations = {
    ["Làng Lá"] = CFrame.new(-300, 10, 200),
    ["Làng Cát"] = CFrame.new(800, 10, -400),
    ["Làng Sương Mù"] = CFrame.new(200, 10, 900),
    ["Thác Nước"] = CFrame.new(0, 50, -800),
    ["Rừng Chết"] = CFrame.new(-700, 10, -300),
}
local bodyVelocity, bodyGyro

-- ================== HÀM TÌM KIẾM REMOTE ==================
local function getDamageRemote()
    -- Tìm RemoteEvent gây sát thương
    for _,v in pairs(ReplicatedStorage:GetDescendants()) do
        if v:IsA("RemoteEvent") and (v.Name == "Damage" or v.Name == "CastSpell" or v.Name == "Attack") then
            return v
        end
    end
    return nil
end

local function getEquipRemote()
    -- Tìm Remote trang bị skill
    for _,v in pairs(ReplicatedStorage:GetDescendants()) do
        if v:IsA("RemoteEvent") and (v.Name == "Equip" or v.Name == "SelectSkill") then
            return v
        end
    end
    return nil
end

local damageRemote = getDamageRemote()
local equipRemote = getEquipRemote()

-- ================== HÀM UTIL ==================
local function findNearestEnemy(range)
    local character = LocalPlayer.Character
    if not character then return nil end
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end
    local nearest, minDist = nil, range or 200
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") and obj ~= character then
            local hum = obj:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then
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

local function findScroll()
    scrollList = {}
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") and (obj.Name:lower():find("scroll") or obj.Name:lower():find("paper")) then
            table.insert(scrollList, obj)
        end
    end
    return scrollList[1] -- trả về cái đầu tiên
end

local function teleportToCFrame(cf)
    local character = LocalPlayer.Character
    if not character then return end
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    if noclipEnabled then
        hrp.CFrame = cf
    else
        TweenService:Create(hrp, TweenInfo.new(0.5, Enum.EasingStyle.Linear), {CFrame = cf}):Play()
    end
end

-- ================== CHỨC NĂNG FLY (JOYSTICK ẢO) ==================
local joystickButton, joystickFrame
local function createJoystick()
    -- Joystick ảo cho mobile
    if joystickFrame then return end
    joystickFrame = Instance.new("Frame")
    joystickFrame.Size = UDim2.new(0, 150, 0, 150)
    joystickFrame.Position = UDim2.new(0, 30, 0.7, 0)
    joystickFrame.BackgroundTransparency = 0.7
    joystickFrame.BackgroundColor3 = Color3.new(0,0,0)
    joystickFrame.BorderSizePixel = 0
    joystickFrame.Active = true
    joystickFrame.Visible = false
    joystickFrame.Parent = mainGui

    joystickButton = Instance.new("ImageButton")
    joystickButton.Size = UDim2.new(0, 60, 0, 60)
    joystickButton.Position = UDim2.new(0.5, -30, 0.5, -30)
    joystickButton.BackgroundColor3 = Color3.new(1,1,1)
    joystickButton.BackgroundTransparency = 0.5
    joystickButton.Image = "rbxassetid://0" -- vòng tròn
    joystickButton.Parent = joystickFrame
end

local function toggleFly()
    flyEnabled = not flyEnabled
    local character = LocalPlayer.Character
    if not character then return end
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    if flyEnabled then
        bodyVelocity = Instance.new("BodyVelocity")
        bodyVelocity.MaxForce = Vector3.new(1,1,1) * math.huge
        bodyVelocity.Velocity = Vector3.new(0,0,0)
        bodyVelocity.Parent = hrp
        bodyGyro = Instance.new("BodyGyro")
        bodyGyro.MaxTorque = Vector3.new(1,1,1) * math.huge
        bodyGyro.CFrame = hrp.CFrame
        bodyGyro.Parent = hrp
        joystickFrame.Visible = true
        -- Kết nối sự kiện joystick
        local moving = false
        joystickButton.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Touch then
                moving = true
            end
        end)
        joystickButton.InputChanged:Connect(function(input)
            if moving and input.UserInputType == Enum.UserInputType.Touch then
                local delta = input.Position - joystickButton.AbsolutePosition - joystickButton.AbsoluteSize/2
                local direction = Vector3.new(delta.X, 0, delta.Y) * flySpeed/50
                bodyVelocity.Velocity = Vector3.new(direction.X, 0, direction.Z) + Vector3.new(0, delta.Y>0 and flySpeed/2 or -flySpeed/2, 0)
            end
        end)
        joystickButton.InputEnded:Connect(function(input)
            moving = false
            bodyVelocity.Velocity = Vector3.new(0,0,0)
        end)
    else
        if bodyVelocity then bodyVelocity:Destroy() end
        if bodyGyro then bodyGyro:Destroy() end
        joystickFrame.Visible = false
    end
end

-- ================== NOCLIP ==================
local function toggleNoclip()
    noclipEnabled = not noclipEnabled
    local character = LocalPlayer.Character
    if character then
        for _, part in ipairs(character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = not noclipEnabled
            end
        end
    end
end

-- ================== AUTO FARM + SPAM SKILL ==================
local farmConnection
local function toggleAutoFarm()
    autoFarmEnabled = not autoFarmEnabled
    if autoFarmEnabled then
        farmConnection = RunService.RenderStepped:Connect(function()
            if not autoFarmEnabled then return end
            local target = findNearestEnemy(farmRange)
            if target and target:FindFirstChild("HumanoidRootPart") then
                teleportToCFrame(target.HumanoidRootPart.CFrame + Vector3.new(0,3,0))
                if spamSkill and damageRemote then
                    -- Spam skill: gửi yêu cầu tấn công
                    pcall(function()
                        damageRemote:FireServer(target, "Skill1") -- thay bằng tên skill nếu cần
                    end)
                end
            end
        end)
    else
        if farmConnection then farmConnection:Disconnect() end
    end
end

-- ================== AUTO BOSS ==================
local bossConnection
local function toggleAutoBoss()
    autoBossEnabled = not autoBossEnabled
    if autoBossEnabled then
        bossConnection = RunService.RenderStepped:Connect(function()
            if not autoBossEnabled then return end
            local boss = findBoss(targetBoss)
            if boss and boss:FindFirstChild("HumanoidRootPart") then
                teleportToCFrame(boss.HumanoidRootPart.CFrame + Vector3.new(0,5,0))
                if spamSkill and damageRemote then
                    pcall(function()
                        damageRemote:FireServer(boss, "Ultimate") -- dùng skill mạnh
                    end)
                end
            end
        end)
    else
        if bossConnection then bossConnection:Disconnect() end
    end
end

-- ================== AUTO SCROLL ==================
local scrollConnection
local function toggleAutoScroll()
    autoScrollEnabled = not autoScrollEnabled
    if autoScrollEnabled then
        scrollConnection = RunService.RenderStepped:Connect(function()
            if not autoScrollEnabled then return end
            local scroll = findScroll()
            if scroll and scroll:FindFirstChild("Part") then
                teleportToCFrame(scroll.Part.CFrame)
                -- Giả lập nhặt (touch interest)
                firetouchinterest(LocalPlayer.Character.HumanoidRootPart, scroll.Part, 0)
                wait(0.5)
            end
        end)
    else
        if scrollConnection then scrollConnection:Disconnect() end
    end
end

-- ================== GIAO DIỆN CHÍNH ==================
local function createMainGui()
    if mainGui then mainGui:Destroy() end
    mainGui = Instance.new("ScreenGui")
    mainGui.Name = "ShindoPro"
    mainGui.ResetOnSpawn = false
    mainGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

    -- Nút toggle ẩn/hiện (nhỏ, trong suốt)
    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Size = UDim2.new(0, 50, 0, 50)
    toggleBtn.Position = UDim2.new(0, 10, 0.5, -25)
    toggleBtn.BackgroundColor3 = Color3.new(0.2,0.2,0.2)
    toggleBtn.BackgroundTransparency = 0.5
    toggleBtn.Text = "+"
    toggleBtn.TextColor3 = Color3.new(1,1,1)
    toggleBtn.TextSize = 30
    toggleBtn.Font = Enum.Font.SourceSansBold
    toggleBtn.ZIndex = 10
    toggleBtn.Parent = mainGui
    local mainFrame

    toggleBtn.MouseButton1Click:Connect(function()
        guiVisible = not guiVisible
        if mainFrame then mainFrame.Visible = guiVisible end
        if joystickFrame then joystickFrame.Visible = flyEnabled and guiVisible end
        toggleBtn.Text = guiVisible and "-" or "+"
    end)

    -- Khung chính
    mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 300, 0, 400)
    mainFrame.Position = UDim2.new(0, 10, 0.5, -200)
    mainFrame.BackgroundColor3 = Color3.new(0.1,0.1,0.1)
    mainFrame.BorderSizePixel = 0
    mainFrame.Visible = true
    mainFrame.Parent = mainGui
    Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0,12)
    Instance.new("UIStroke", mainFrame).Color = Color3.new(0.5,0,0.5)

    -- Tiêu đề
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1,0,0,30)
    title.BackgroundColor3 = Color3.new(0.2,0.2,0.2)
    title.TextColor3 = Color3.new(1,1,1)
    title.Font = Enum.Font.SourceSansBold
    title.Text = "SHINDO LIFE PRO v2.0"
    title.TextSize = 16
    title.Parent = mainFrame
    Instance.new("UICorner", title)

    -- Tab system
    local tabButtons = {"Main","Farm","Boss","Scroll","Tele","Set"}
    local tabs = {}
    local tabContainer = Instance.new("Frame")
    tabContainer.Size = UDim2.new(1,0,1,-35)
    tabContainer.Position = UDim2.new(0,0,0,35)
    tabContainer.BackgroundTransparency = 1
    tabContainer.Parent = mainFrame

    local function createTab(name)
        local tab = Instance.new("Frame")
        tab.Size = UDim2.new(1,0,1,0)
        tab.BackgroundTransparency = 1
        tab.Visible = false
        tab.Parent = tabContainer
        return tab
    end

    local tabMain = createTab("Main")
    local tabFarm = createTab("Farm")
    local tabBoss = createTab("Boss")
    local tabScroll = createTab("Scroll")
    local tabTele = createTab("Tele")
    local tabSet = createTab("Set")
    tabs = {Main=tabMain, Farm=tabFarm, Boss=tabBoss, Scroll=tabScroll, Tele=tabTele, Set=tabSet}

    -- Tab buttons
    local function switchTab(tabName)
        for _, t in pairs(tabs) do t.Visible = false end
        tabs[tabName].Visible = true
    end

    -- Tạo nút tab
    local btnWidth = 1/#tabButtons
    for i, name in ipairs(tabButtons) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(btnWidth,0,0,25)
        btn.Position = UDim2.new((i-1)*btnWidth,0,0,0)
        btn.BackgroundColor3 = Color3.new(0.3,0.3,0.3)
        btn.TextColor3 = Color3.new(1,1,1)
        btn.Font = Enum.Font.SourceSans
        btn.Text = name
        btn.TextSize = 14
        btn.Parent = title
        btn.MouseButton1Click:Connect(function()
            switchTab(name)
        end)
    end

    -- Nội dung tab Main
    -- Fly, Noclip, AutoFarm, AutoBoss, AutoScroll toggles
    local function addToggleButton(parent, text, y, callback)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1,-20,0,35)
        btn.Position = UDim2.new(0,10,0,y)
        btn.BackgroundColor3 = Color3.new(0.4,0.4,0.4)
        btn.TextColor3 = Color3.new(1,1,1)
        btn.Font = Enum.Font.SourceSans
        btn.Text = text .. ": OFF"
        btn.TextSize = 14
        btn.Parent = parent
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0,6)
        local enabled = false
        btn.MouseButton1Click:Connect(function()
            enabled = not enabled
            btn.Text = text .. ": " .. (enabled and "ON" or "OFF")
            btn.BackgroundColor3 = enabled and Color3.new(0.2,0.8,0.2) or Color3.new(0.4,0.4,0.4)
            callback(enabled)
        end)
        return btn
    end

    addToggleButton(tabMain, "Bay (Fly)", 10, function(on) toggleFly() end)
    addToggleButton(tabMain, "Xuyên Tường", 50, function(on) toggleNoclip() end)
    addToggleButton(tabMain, "Auto Farm", 90, function(on) toggleAutoFarm() end)
    addToggleButton(tabMain, "Auto Boss", 130, function(on) toggleAutoBoss() end)
    addToggleButton(tabMain, "Auto Scroll", 170, function(on) toggleAutoScroll() end)

    -- Tab Farm: Spam Skill, phạm vi
    local spamToggle = addToggleButton(tabFarm, "Spam Skill", 10, function(on) spamSkill = on end)
    spamToggle.Text = "Spam Skill: ON"
    spamToggle.BackgroundColor3 = Color3.new(0.2,0.8,0.2)
    local rangeSlider = Instance.new("TextBox")
    rangeSlider.Size = UDim2.new(1,-20,0,30)
    rangeSlider.Position = UDim2.new(0,10,0,50)
    rangeSlider.BackgroundColor3 = Color3.new(0.3,0.3,0.3)
    rangeSlider.TextColor3 = Color3.new(1,1,1)
    rangeSlider.PlaceholderText = "Phạm vi (mặc định 150)"
    rangeSlider.Text = "150"
    rangeSlider.Parent = tabFarm
    rangeSlider.FocusLost:Connect(function()
        farmRange = tonumber(rangeSlider.Text) or 150
    end)

    -- Tab Boss: chọn boss
    local bossList = {"Tất cả", "Akuma", "Tengoku", "Renshiki", "Forge Boss"}
    for i, name in ipairs(bossList) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1,-20,0,30)
        btn.Position = UDim2.new(0,10,0,10+(i-1)*35)
        btn.BackgroundColor3 = Color3.new(0.4,0.4,0.4)
        btn.TextColor3 = Color3.new(1,1,1)
        btn.Text = name
        btn.Parent = tabBoss
        btn.MouseButton1Click:Connect(function()
            targetBoss = name
        end)
    end

    -- Tab Scroll: nút làm mới, danh sách scroll
    local refreshBtn = Instance.new("TextButton")
    refreshBtn.Size = UDim2.new(1,-20,0,30)
    refreshBtn.Position = UDim2.new(0,10,0,10)
    refreshBtn.Text = "Làm mới danh sách scroll"
    refreshBtn.BackgroundColor3 = Color3.new(0.4,0.4,0.4)
    refreshBtn.TextColor3 = Color3.new(1,1,1)
    refreshBtn.Parent = tabScroll
    refreshBtn.MouseButton1Click:Connect(function()
        findScroll()
        local scrollFrame = tabScroll:FindFirstChild("ScrollList")
        if scrollFrame then
            for _, v in ipairs(scrollFrame:GetChildren()) do
                if v:IsA("TextButton") then v:Destroy() end
            end
            for i, scroll in ipairs(scrollList) do
                local btn = Instance.new("TextButton")
                btn.Size = UDim2.new(1,0,0,25)
                btn.Position = UDim2.new(0,0,0,(i-1)*25)
                btn.Text = scroll.Name .. " [" .. math.floor((scroll.Part.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude) .. "m]"
                btn.BackgroundColor3 = Color3.new(0.3,0.3,0.3)
                btn.TextColor3 = Color3.new(1,1,1)
                btn.Parent = scrollFrame
                btn.MouseButton1Click:Connect(function()
                    teleportToCFrame(scroll.Part.CFrame)
                end)
            end
        end
    end)
    local scrollListFrame = Instance.new("ScrollingFrame")
    scrollListFrame.Size = UDim2.new(1,-20,1,-50)
    scrollListFrame.Position = UDim2.new(0,10,0,50)
    scrollListFrame.BackgroundColor3 = Color3.new(0.2,0.2,0.2)
    scrollListFrame.Name = "ScrollList"
    scrollListFrame.CanvasSize = UDim2.new(0,0,0,0)
    scrollListFrame.Parent = tabScroll

    -- Tab Teleport: địa điểm
    local teleFrame = Instance.new("ScrollingFrame")
    teleFrame.Size = UDim2.new(1,-20,1,-10)
    teleFrame.Position = UDim2.new(0,10,0,10)
    teleFrame.BackgroundColor3 = Color3.new(0.2,0.2,0.2)
    teleFrame.CanvasSize = UDim2.new(0,0,0,#teleportLocations*30)
    teleFrame.Parent = tabTele
    local i = 0
    for name, cf in pairs(teleportLocations) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1,0,0,25)
        btn.Position = UDim2.new(0,0,0,i*25)
        btn.Text = name
        btn.BackgroundColor3 = Color3.new(0.3,0.3,0.3)
        btn.TextColor3 = Color3.new(1,1,1)
        btn.Parent = teleFrame
        btn.MouseButton1Click:Connect(function()
            teleportToCFrame(cf)
        end)
        i = i+1
    end
    teleFrame.CanvasSize = UDim2.new(0,0,0,i*25)

    -- Tab Settings: tốc độ bay
    local speedInput = Instance.new("TextBox")
    speedInput.Size = UDim2.new(1,-20,0,30)
    speedInput.Position = UDim2.new(0,10,0,10)
    speedInput.BackgroundColor3 = Color3.new(0.3,0.3,0.3)
    speedInput.TextColor3 = Color3.new(1,1,1)
    speedInput.PlaceholderText = "Tốc độ bay (mặc định 50)"
    speedInput.Text = "50"
    speedInput.Parent = tabSet
    speedInput.FocusLost:Connect(function()
        flySpeed = tonumber(speedInput.Text) or 50
    end)

    -- Joystick khởi tạo
    createJoystick()
end

-- Chạy khi vào game
LocalPlayer.CharacterAdded:Connect(function()
    createMainGui()
end)

createMainGui()

print("Shindo Life Pro Mobile loaded! Tap '+' to toggle GUI.")
