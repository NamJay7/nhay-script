--[[
    SHINDO LIFE PRO – PHIÊN BẢN HOÀN CHỈNH CHO DELTA X MOBILE
    - Auto Farm Level: tự nhận quest, đánh quái (phân biệt player/boss/gỗ), nộp quest, loop.
    - ESP: định vị người chơi, scroll, vật phẩm rơi (Billboard 2D).
    - Spam skill kết hợp M1, phạm vi farm xa.
    - Menu kéo thả, hiện đại, màu xanh biển.
    - Boss farm (placeholder).
]]

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInputManager = game:GetService("VirtualInputManager")
local TweenService = game:GetService("TweenService")

-- ================== TÌM REMOTE ==================
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

-- ================== BIẾN TOÀN CỤC ==================
local autoFarmEnabled = false
local autoChakraEnabled = false
local autoScrollEnabled = false
local espEnabled = false
local farmRange = 250
local mainSkill = "Skill1"
local useM1 = true

-- ================== TIỆN ÍCH ==================
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
            if gui:IsA("BillboardGui") then
                local tl = gui:FindFirstChild("TextLabel")
                if tl and tl.Text == "!" then return false end
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
                local d = (hrp.Position - root.Position).Magnitude
                if d < minDist then
                    minDist = d
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
                            if (tl and tl.Text == "!") or (il and il.Image:find("exclamation")) then return obj end
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
    local scrolls = {}
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") and (obj.Name:lower():find("scroll") or obj.Name:lower():find("paper")) then
            table.insert(scrolls, obj)
        end
    end
    return scrolls
end

local function findLootItems()
    local items = {}
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") and (obj.Name:lower():find("item") or obj.Name:lower():find("loot") or obj.Name:lower():find("drop")) then
            local part = obj:FindFirstChild("Part") or obj:FindFirstChild("Handle")
            if part then table.insert(items, obj) end
        end
    end
    return items
end

-- Tấn công kết hợp M1 + skill
local function attackTarget(target, skillName)
    if not target then return end
    skillName = skillName or mainSkill
    local root = target:FindFirstChild("HumanoidRootPart")
    if not root then return end
    -- M1 (click chuột trái)
    if useM1 then
        if damageRemote then pcall(function() damageRemote:FireServer(target, "M1") end)
        else
            local pos, onScreen = Workspace.CurrentCamera:WorldToViewportPoint(root.Position)
            if onScreen then
                VirtualInputManager:SendMouseButtonEvent(pos.X, pos.Y, 0, true, game, 1)
                task.wait(0.05)
                VirtualInputManager:SendMouseButtonEvent(pos.X, pos.Y, 0, false, game, 1)
            end
        end
        task.wait(0.08)
    end
    -- Skill
    if damageRemote then pcall(function() damageRemote:FireServer(target, skillName) end)
    else
        local pos, onScreen = Workspace.CurrentCamera:WorldToViewportPoint(root.Position)
        if onScreen then
            VirtualInputManager:SendMouseButtonEvent(pos.X, pos.Y, 0, true, game, 1)
            task.wait(0.05)
            VirtualInputManager:SendMouseButtonEvent(pos.X, pos.Y, 0, false, game, 1)
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

-- ================== AUTO FARM LEVEL ==================
local farmThread
function toggleAutoFarm()
    autoFarmEnabled = not autoFarmEnabled
    if autoFarmEnabled then
        farmThread = task.spawn(function()
            while autoFarmEnabled do
                local npc = findQuestNPC()
                if npc then
                    local npcHRP = npc:FindFirstChild("HumanoidRootPart")
                    if npcHRP then TweenService:Create(LocalPlayer.Character.HumanoidRootPart, TweenInfo.new(0.5), {CFrame = npcHRP.CFrame + Vector3.new(0,3,5)}):Play() end
                    task.wait(0.5)
                    local head = npc:FindFirstChild("Head")
                    if head then
                        local pos = Workspace.CurrentCamera:WorldToViewportPoint(head.Position)
                        VirtualInputManager:SendMouseButtonEvent(pos.X, pos.Y, 0, true, game, 1)
                        task.wait(0.1)
                        VirtualInputManager:SendMouseButtonEvent(pos.X, pos.Y, 0, false, game, 1)
                    end
                    task.wait(1.5)
                    local pg = LocalPlayer:FindFirstChild("PlayerGui")
                    local acceptBtn = pg and (pg:FindFirstChild("Accept") or pg:FindFirstChild("Yes"))
                    if acceptBtn and acceptBtn:IsA("TextButton") then
                        local btnPos = acceptBtn.AbsolutePosition + acceptBtn.AbsoluteSize/2
                        VirtualInputManager:SendMouseButtonEvent(btnPos.X, btnPos.Y, 0, true, game, 1)
                        task.wait(0.1)
                        VirtualInputManager:SendMouseButtonEvent(btnPos.X, btnPos.Y, 0, false, game, 1)
                    end
                    task.wait(1)
                    -- Farm
                    local startTime = tick()
                    while autoFarmEnabled and (tick() - startTime) < 20 do
                        local target = findNearestEnemy(farmRange)
                        if target then
                            TweenService:Create(LocalPlayer.Character.HumanoidRootPart, TweenInfo.new(0.2), {CFrame = target.HumanoidRootPart.CFrame * CFrame.new(0, -2, 0)}):Play()
                            attackTarget(target, mainSkill)
                        end
                        task.wait(0.25)
                    end
                    -- Nộp quest
                    if npcHRP then TweenService:Create(LocalPlayer.Character.HumanoidRootPart, TweenInfo.new(0.5), {CFrame = npcHRP.CFrame + Vector3.new(0,3,5)}):Play() end
                    task.wait(0.5)
                    if head then
                        local pos = Workspace.CurrentCamera:WorldToViewportPoint(head.Position)
                        VirtualInputManager:SendMouseButtonEvent(pos.X, pos.Y, 0, true, game, 1)
                        task.wait(0.1)
                        VirtualInputManager:SendMouseButtonEvent(pos.X, pos.Y, 0, false, game, 1)
                    end
                    task.wait(1.5)
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

-- ================== AUTO CHAKRA ==================
local chakraThread
function toggleAutoChakra()
    autoChakraEnabled = not autoChakraEnabled
    if autoChakraEnabled then
        chakraThread = task.spawn(function()
            while autoChakraEnabled do
                if getChakraPercent() < 30 then chargeChakra() end
                task.wait(1)
            end
        end)
    else if chakraThread then task.cancel(chakraThread) end end
end

-- ================== ESP ==================
local espGui, espContainer
local function createESP()
    if espGui then espGui:Destroy() end
    espGui = Instance.new("ScreenGui")
    espGui.Name = "ESP"
    espGui.ResetOnSpawn = false
    espGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    espContainer = Instance.new("Frame")
    espContainer.Size = UDim2.new(1,0,1,0)
    espContainer.BackgroundTransparency = 1
    espContainer.Parent = espGui
end

local function updateESP()
    -- Xóa cũ
    for _, v in ipairs(espContainer:GetChildren()) do
        if v:IsA("Frame") or v:IsA("TextLabel") then v:Destroy() end
    end
    if not espEnabled then return end
    local camera = Workspace.CurrentCamera
    -- Người chơi
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local char = player.Character
            local head = char:FindFirstChild("Head")
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if head and hrp then
                local pos, onScreen = camera:WorldToViewportPoint(hrp.Position + Vector3.new(0,2,0))
                if onScreen then
                    local box = Instance.new("Frame")
                    box.Size = UDim2.new(0, 2, 0, 2)
                    box.Position = UDim2.new(0, pos.X, 0, pos.Y)
                    box.BackgroundColor3 = Color3.new(1,0,0)
                    box.Parent = espContainer
                    local name = Instance.new("TextLabel")
                    name.Text = player.Name
                    name.TextColor3 = Color3.new(1,1,1)
                    name.TextSize = 12
                    name.BackgroundTransparency = 1
                    name.Position = UDim2.new(0, pos.X, 0, pos.Y - 20)
                    name.Parent = espContainer
                end
            end
        end
    end
    -- Scroll
    for _, scroll in ipairs(findScrolls()) do
        local part = scroll:FindFirstChild("Part") or scroll:FindFirstChild("Handle")
        if part then
            local pos, onScreen = camera:WorldToViewportPoint(part.Position)
            if onScreen then
                local box = Instance.new("Frame")
                box.Size = UDim2.new(0, 4, 0, 4)
                box.Position = UDim2.new(0, pos.X, 0, pos.Y)
                box.BackgroundColor3 = Color3.new(1,1,0) -- vàng
                box.Parent = espContainer
            end
        end
    end
    -- Loot items
    for _, item in ipairs(findLootItems()) do
        local part = item:FindFirstChild("Part") or item:FindFirstChild("Handle")
        if part then
            local pos, onScreen = camera:WorldToViewportPoint(part.Position)
            if onScreen then
                local box = Instance.new("Frame")
                box.Size = UDim2.new(0, 3, 0, 3)
                box.Position = UDim2.new(0, pos.X, 0, pos.Y)
                box.BackgroundColor3 = Color3.new(0,1,0) -- xanh lá
                box.Parent = espContainer
            end
        end
    end
end

local function toggleESP()
    espEnabled = not espEnabled
    if espEnabled then
        createESP()
        task.spawn(function()
            while espEnabled do
                updateESP()
                task.wait(0.5)
            end
            if espGui then espGui:Destroy() end
        end)
    else
        if espGui then espGui:Destroy() end
    end
end

-- ================== GIAO DIỆN ==================
local mainGui = Instance.new("ScreenGui")
mainGui.Name = "ShindoPro"
mainGui.ResetOnSpawn = false
mainGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

-- Nút toggle menu
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

local guiVisible = false
local mainFrame

local function toggleMenu()
    guiVisible = not guiVisible
    if mainFrame then mainFrame.Visible = guiVisible end
    toggleBtn.Text = guiVisible and "−" or "+"
end

toggleBtn.MouseButton1Click:Connect(toggleMenu)
toggleBtn.Activated:Connect(toggleMenu)

-- Menu chính
mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 320, 0, 420)
mainFrame.Position = UDim2.new(0, 100, 0.5, -210)
mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
mainFrame.BorderSizePixel = 0
mainFrame.Visible = false
mainFrame.Parent = mainGui
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0,12)

-- Thanh tiêu đề
local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1,0,0,35)
titleBar.BackgroundColor3 = Color3.fromRGB(70,130,180)
titleBar.BorderSizePixel = 0
titleBar.Parent = mainFrame

local titleText = Instance.new("TextLabel")
titleText.Size = UDim2.new(1,0,1,0)
titleText.BackgroundTransparency = 1
titleText.Text = "Shindo Pro | v1.0"
titleText.TextColor3 = Color3.new(1,1,1)
titleText.Font = Enum.Font.SourceSansBold
titleText.TextSize = 16
titleText.Parent = titleBar

-- Kéo thả
local dragging, dragStart, startPos
titleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = mainFrame.Position
        input.UserInputState = Enum.UserInputState.Began
    end
end)
titleBar.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
        local delta = input.Position - dragStart
        mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)
titleBar.InputEnded:Connect(function() dragging = false end)

-- Tab
local tabContainer = Instance.new("Frame")
tabContainer.Size = UDim2.new(1,0,1,-35)
tabContainer.Position = UDim2.new(0,0,0,35)
tabContainer.BackgroundTransparency = 1
tabContainer.Parent = mainFrame

local tabs = {}
local function addTab(name, icon)
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
local tabSetting = addTab("Setting")
tabs["Main"].Visible = true

-- Nút tab
local tabWidth = 1/3
local tabNames = {"Main", "ESP", "Setting"}
for i, name in ipairs(tabNames) do
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(tabWidth, 0, 0, 25)
    btn.Position = UDim2.new((i-1)*tabWidth, 0, 0, 0)
    btn.BackgroundColor3 = Color3.fromRGB(70,130,180)
    btn.TextColor3 = Color3.new(1,1,1)
    btn.Text = name
    btn.Font = Enum.Font.SourceSans
    btn.TextSize = 14
    btn.Parent = titleBar
    btn.MouseButton1Click:Connect(function()
        for _, t in pairs(tabs) do t.Visible = false end
        tabs[name].Visible = true
    end)
end

-- Hàm tạo toggle trong tab
local function addToggle(tab, text, y, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -20, 0, 35)
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
    return btn
end

-- Tab Main
addToggle(tabMain, "Auto Farm Level", 10, function(on) toggleAutoFarm() end)
addToggle(tabMain, "Auto Chakra", 50, function(on) toggleAutoChakra() end)
addToggle(tabMain, "Auto Scroll", 90, function(on) toggleAutoScroll() end)

-- Tab ESP
addToggle(tabESP, "Bật ESP", 10, function(on) toggleESP() end)

-- Tab Setting
local skillLabel = Instance.new("TextLabel")
skillLabel.Size = UDim2.new(1, -20, 0, 25)
skillLabel.Position = UDim2.new(0, 10, 0, 10)
skillLabel.BackgroundTransparency = 1
skillLabel.Text = "Skill Chính:"
skillLabel.TextColor3 = Color3.new(1,1,1)
skillLabel.Font = Enum.Font.SourceSans
skillLabel.TextSize = 14
skillLabel.Parent = tabSetting

local skillInput = Instance.new("TextBox")
skillInput.Size = UDim2.new(1, -20, 0, 30)
skillInput.Position = UDim2.new(0, 10, 0, 35)
skillInput.BackgroundColor3 = Color3.fromRGB(100,149,237)
skillInput.TextColor3 = Color3.new(1,1,1)
skillInput.Text = mainSkill
skillInput.Font = Enum.Font.SourceSans
skillInput.TextSize = 14
skillInput.Parent = tabSetting
skillInput.FocusLost:Connect(function()
    mainSkill = skillInput.Text ~= "" and skillInput.Text or "Skill1"
end)

local rangeLabel = Instance.new("TextLabel")
rangeLabel.Size = UDim2.new(1, -20, 0, 25)
rangeLabel.Position = UDim2.new(0, 10, 0, 75)
rangeLabel.BackgroundTransparency = 1
rangeLabel.Text = "Phạm vi farm:"
rangeLabel.TextColor3 = Color3.new(1,1,1)
rangeLabel.Font = Enum.Font.SourceSans
rangeLabel.TextSize = 14
rangeLabel.Parent = tabSetting

local rangeInput = Instance.new("TextBox")
rangeInput.Size = UDim2.new(1, -20, 0, 30)
rangeInput.Position = UDim2.new(0, 10, 0, 100)
rangeInput.BackgroundColor3 = Color3.fromRGB(100,149,237)
rangeInput.TextColor3 = Color3.new(1,1,1)
rangeInput.Text = tostring(farmRange)
rangeInput.Font = Enum.Font.SourceSans
rangeInput.TextSize = 14
rangeInput.Parent = tabSetting
rangeInput.FocusLost:Connect(function()
    farmRange = tonumber(rangeInput.Text) or 250
end)

-- ESP chạy nền
task.spawn(function()
    while true do
        if espEnabled then updateESP() end
        task.wait(0.5)
    end
end)

print("Shindo Life Pro Mobile loaded! Bấm nút '+' để mở menu.")
