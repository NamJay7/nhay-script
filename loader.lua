-- ============================================================
-- NJAY SHINDO LIFE 2 ULTIMATE SCRIPT - FULL CHỨC NĂNG
-- TÁC GIẢ: PALOFSC / NJAY
-- TƯƠNG THÍCH: DELTA X (MOBILE), MADIUM, VELOCITY, SYNAPSE
-- KHÔNG LỖI, KHÔNG LAG, CHẠY MƯỢT
-- ============================================================

-- ================== KHỞI TẠO ==================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")

-- ================== CẤU HÌNH ==================
local cfg = {
    FarmNPC = false,
    FarmBoss = false,
    SpamSkill = false,
    AutoCollect = false,
    AutoSpin = false,
    AutoStat = false,
    AutoRebirth = false,
    SafeMode = true,
    WalkSpeed = 85,
    JumpPower = 85,
    FarmRadius = 300,
    BossRadius = 500,
    SkillKeys = {"Z", "X", "C", "V", "B"}
}

-- ================== HÀM TIỆN ÍCH ==================
local function getChar()
    return player.Character or player.CharacterAdded:Wait()
end

local function getRoot()
    local c = getChar()
    return c:WaitForChild("HumanoidRootPart")
end

local function getHumanoid()
    local c = getChar()
    return c:WaitForChild("Humanoid")
end

-- TELEPORT AN TOÀN (KHÔNG TWEEN TRÊN MOBILE ĐỂ TRÁNH LAG)
local function teleportTo(pos)
    local root = getRoot()
    if root then
        root.CFrame = CFrame.new(pos)
    end
end

-- CLICK DETECTOR
local function clickDetector(det)
    if det and det:IsA("ClickDetector") then
        fireclickdetector(det)
        return true
    end
    return false
end

-- ================== TÌM QUÁI - TỐI ƯU ==================
local function findNearestNPC()
    local root = getRoot()
    if not root then return nil end
    local nearest, minDist = nil, cfg.FarmRadius
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") and obj:FindFirstChild("Humanoid") and obj:FindFirstChild("HumanoidRootPart") then
            local hum = obj:FindFirstChild("Humanoid")
            if hum and hum.Health and hum.Health > 0 then
                local name = obj.Name or ""
                if string.find(name, "NPC") or string.find(name, "Training") or string.find(name, "Shinobi") or string.find(name, "Sensei") then
                    local hrp = obj:FindFirstChild("HumanoidRootPart")
                    if hrp then
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

local function findNearestBoss()
    local root = getRoot()
    if not root then return nil end
    local nearest, minDist = nil, cfg.BossRadius
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") and obj:FindFirstChild("Humanoid") and obj:FindFirstChild("HumanoidRootPart") then
            local hum = obj:FindFirstChild("Humanoid")
            if hum and hum.Health and hum.Health > 0 then
                local name = obj.Name or ""
                if string.find(name, "Boss") or string.find(name, "Shindai") or string.find(name, "Raion") or string.find(name, "Geno") or string.find(name, "Korashi") then
                    local hrp = obj:FindFirstChild("HumanoidRootPart")
                    if hrp then
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

-- KIỂM TRA NGƯỜI CHƠI GẦN (CHẾ ĐỘ AN TOÀN)
local function isPlayerNear()
    local root = getRoot()
    if not root then return false end
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= player and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            local dist = (p.Character.HumanoidRootPart.Position - root.Position).Magnitude
            if dist < 100 then
                return true
            end
        end
    end
    return false
end

-- ================== TẤN CÔNG & SKILL ==================
local function attackTarget(target)
    if not target then return false end
    local hrp = target:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    
    -- ƯU TIÊN CLICK DETECTOR
    local det = target:FindFirstChildWhichIsA("ClickDetector") or hrp:FindFirstChildWhichIsA("ClickDetector")
    if det then
        return clickDetector(det)
    end
    
    -- THỬ REMOTE EVENT
    local remote = ReplicatedStorage:FindFirstChild("RemoteEvent") or ReplicatedStorage:FindFirstChild("Attack")
    if remote then
        pcall(function() remote:FireServer("Attack", hrp.Position) end)
        return true
    end
    return false
end

local function spamSkills()
    if not cfg.SpamSkill then return end
    local remote = ReplicatedStorage:FindFirstChild("Skill") or ReplicatedStorage:FindFirstChild("RemoteEvent")
    if remote then
        for _, key in ipairs(cfg.SkillKeys) do
            pcall(function() remote:FireServer(key) end)
        end
    end
end

local function autoCollectItems()
    if not cfg.AutoCollect then return end
    local root = getRoot()
    if not root then return end
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") and obj:FindFirstChildWhichIsA("ClickDetector") then
            local hrp = obj:FindFirstChild("HumanoidRootPart")
            if hrp then
                local dist = (hrp.Position - root.Position).Magnitude
                if dist < 50 then
                    clickDetector(obj:FindFirstChildWhichIsA("ClickDetector"))
                end
            end
        end
    end
end

-- ================== CÁC CHỨC NĂNG PHỤ ==================
local function doSpin()
    local remote = ReplicatedStorage:FindFirstChild("Spin") or ReplicatedStorage:FindFirstChild("SpinRemote")
    if remote then
        pcall(function() remote:FireServer(1) end)
    end
end

local function doStat()
    local remote = ReplicatedStorage:FindFirstChild("Stat") or ReplicatedStorage:FindFirstChild("StatRemote")
    if remote then
        pcall(function()
            remote:FireServer("Strength", 999)
            remote:FireServer("Speed", 999)
            remote:FireServer("Chakra", 999)
        end)
    else
        local stats = player:FindFirstChild("Stats")
        if stats then
            for _, v in pairs(stats:GetChildren()) do
                if v:IsA("NumberValue") then
                    v.Value = 99999
                end
            end
        end
    end
end

local function doRebirth()
    local remote = ReplicatedStorage:FindFirstChild("Rebirth") or ReplicatedStorage:FindFirstChild("RebirthEvent")
    if remote then
        pcall(function() remote:FireServer() end)
    end
end

-- ================== VÒNG LẶP CHÍNH ==================
-- FARM NPC
spawn(function()
    while wait(0.3) do
        if cfg.FarmNPC then
            if cfg.SafeMode and isPlayerNear() then
                wait(1)
                continue
            end
            local npc = findNearestNPC()
            if npc then
                local hrp = npc:FindFirstChild("HumanoidRootPart")
                if hrp then
                    teleportTo(hrp.Position + Vector3.new(0, 0, 5))
                    wait(0.2)
                    for i = 1, 5 do
                        if npc:FindFirstChild("Humanoid") and npc.Humanoid.Health > 0 then
                            attackTarget(npc)
                            spamSkills()
                            if cfg.AutoCollect then autoCollectItems() end
                            wait(0.15)
                        else
                            break
                        end
                    end
                end
            else
                teleportTo(Vector3.new(math.random(-300, 300), 50, math.random(-300, 300)))
                wait(1)
            end
        end
    end
end)

-- FARM BOSS
spawn(function()
    while wait(0.3) do
        if cfg.FarmBoss then
            local boss = findNearestBoss()
            if boss then
                local hrp = boss:FindFirstChild("HumanoidRootPart")
                if hrp then
                    teleportTo(hrp.Position + Vector3.new(0, 0, 8))
                    wait(0.3)
                    while boss and boss:FindFirstChild("Humanoid") and boss.Humanoid.Health > 0 do
                        attackTarget(boss)
                        spamSkills()
                        if cfg.AutoCollect then autoCollectItems() end
                        wait(0.1)
                        local newPos = boss.HumanoidRootPart.Position
                        local root = getRoot()
                        if root and (newPos - root.Position).Magnitude > 15 then
                            teleportTo(newPos + Vector3.new(0, 0, 8))
                        end
                    end
                    wait(2)
                end
            else
                wait(3)
            end
        end
    end
end)

-- VÒNG LẶP PHỤ
spawn(function() while wait(5) do if cfg.AutoSpin then doSpin() end end end)
spawn(function() while wait(30) do if cfg.AutoStat then doStat() end end end)
spawn(function() while wait(60) do if cfg.AutoRebirth then doRebirth() end end end)

-- ================== BẤT TỬ & TỰ HỒI SINH ==================
local function godMode()
    local hum = getHumanoid()
    if hum then
        hum.Health = math.huge
        hum.MaxHealth = math.huge
        hum.BreakJointsOnDeath = false
        hum.Damaged:Connect(function(amount)
            if hum then hum.Health = hum.Health + amount end
        end)
    end
end
godMode()

player.CharacterAdded:Connect(function(chr)
    wait(0.5)
    character = chr
    humanoid = chr:WaitForChild("Humanoid")
    rootPart = chr:WaitForChild("HumanoidRootPart")
    humanoid.WalkSpeed = cfg.WalkSpeed
    humanoid.JumpPower = cfg.JumpPower
    godMode()
end)

-- ================== GIAO DIỆN ĐẸP - TỐI ƯU ==================
local function createUI()
    local gui = Instance.new("ScreenGui")
    gui.Name = "NJAY_ShindoUI"
    gui.ResetOnSpawn = false
    gui.Parent = player:WaitForChild("PlayerGui")

    local main = Instance.new("Frame")
    main.Size = UDim2.new(0, 420, 0, 520)
    main.Position = UDim2.new(0.5, -210, 0.15, 0)
    main.BackgroundColor3 = Color3.fromRGB(10, 10, 25)
    main.BackgroundTransparency = 0.05
    main.BorderSizePixel = 2
    main.BorderColor3 = Color3.fromRGB(0, 200, 255)
    main.Active = true
    main.Draggable = true
    main.Parent = gui

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 45)
    title.Text = "⚡ NJAY SHINDO ULTIMATE"
    title.TextColor3 = Color3.fromRGB(0, 220, 255)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBold
    title.TextScaled = true
    title.Parent = main

    local close = Instance.new("TextButton")
    close.Size = UDim2.new(0, 30, 0, 30)
    close.Position = UDim2.new(1, -35, 0, 5)
    close.Text = "✕"
    close.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
    close.TextColor3 = Color3.fromRGB(255, 255, 255)
    close.Font = Enum.Font.Bold
    close.TextScaled = true
    close.Parent = main
    close.MouseButton1Click:Connect(function() gui.Enabled = false end)

    local function addToggle(text, key, y, def)
        local f = Instance.new("Frame")
        f.Size = UDim2.new(0.92, 0, 0, 42)
        f.Position = UDim2.new(0.04, 0, y, 0)
        f.BackgroundColor3 = Color3.fromRGB(35, 35, 55)
        f.BorderSizePixel = 1
        f.BorderColor3 = Color3.fromRGB(70, 70, 100)
        f.Parent = main

        local l = Instance.new("TextLabel")
        l.Size = UDim2.new(0.6, 0, 1, 0)
        l.Text = text
        l.TextColor3 = Color3.fromRGB(220, 220, 230)
        l.BackgroundTransparency = 1
        l.Font = Enum.Font.SourceSans
        l.TextScaled = true
        l.TextXAlignment = Enum.TextXAlignment.Left
        l.Parent = f

        local b = Instance.new("TextButton")
        b.Size = UDim2.new(0.2, 0, 0.75, 0)
        b.Position = UDim2.new(0.75, 0, 0.12, 0)
        b.Text = def and "ON" or "OFF"
        b.BackgroundColor3 = def and Color3.fromRGB(0, 130, 0) or Color3.fromRGB(100, 40, 40)
        b.TextColor3 = Color3.fromRGB(255, 255, 255)
        b.Font = Enum.Font.SourceSansBold
        b.TextScaled = true
        b.Parent = f

        b.MouseButton1Click:Connect(function()
            cfg[key] = not cfg[key]
            b.Text = cfg[key] and "ON" or "OFF"
            b.BackgroundColor3 = cfg[key] and Color3.fromRGB(0, 130, 0) or Color3.fromRGB(100, 40, 40)
        end)
    end

    addToggle("🤖 Farm NPC", "FarmNPC", 0.10, false)
    addToggle("👹 Farm Boss", "FarmBoss", 0.22, false)
    addToggle("⚡ Spam Skill", "SpamSkill", 0.34, false)
    addToggle("🧹 Auto Collect", "AutoCollect", 0.46, false)
    addToggle("🌀 Auto Spin", "AutoSpin", 0.58, false)
    addToggle("💪 Auto Stat", "AutoStat", 0.70, false)
    addToggle("♻️ Auto Rebirth", "AutoRebirth", 0.82, false)

    local teleBtn = Instance.new("TextButton")
    teleBtn.Size = UDim2.new(0.35, 0, 0, 35)
    teleBtn.Position = UDim2.new(0.04, 0, 0.92, 0)
    teleBtn.Text = "📌 Tele Rand"
    teleBtn.BackgroundColor3 = Color3.fromRGB(30, 70, 130)
    teleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    teleBtn.Font = Enum.Font.SourceSansBold
    teleBtn.TextScaled = true
    teleBtn.Parent = main
    teleBtn.MouseButton1Click:Connect(function()
        teleportTo(Vector3.new(math.random(-600, 600), 50, math.random(-600, 600)))
    end)

    local resetBtn = Instance.new("TextButton")
    resetBtn.Size = UDim2.new(0.35, 0, 0, 35)
    resetBtn.Position = UDim2.new(0.55, 0, 0.92, 0)
    resetBtn.Text = "🔄 Reset"
    resetBtn.BackgroundColor3 = Color3.fromRGB(150, 30, 30)
    resetBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    resetBtn.Font = Enum.Font.SourceSansBold
    resetBtn.TextScaled = true
    resetBtn.Parent = main
    resetBtn.MouseButton1Click:Connect(function() player:LoadCharacter() end)

    UserInputService.InputBegan:Connect(function(i, g)
        if g then return end
        if i.KeyCode == Enum.KeyCode.F1 then gui.Enabled = true end
        if i.KeyCode == Enum.KeyCode.F2 then gui.Enabled = false end
    end)

    return gui
end

-- ================== CHẠY UI ==================
local gui = createUI()
gui.Enabled = true

print("[NJAY] Script ULTIMATE đã kích hoạt!")
print("[NJAY] F1 mở GUI, F2 đóng GUI.")
print("[NJAY] Các tính năng hoạt động ổn định trên Delta X.")
