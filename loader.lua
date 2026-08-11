-- DELTAX ULTIMATE v3.0 - CHUYÊN CHO DELTA MOBILE
-- TÁC GIẢ: PALOFSC / NJAY
-- KHÔNG SỬ DỤNG TWEEN, VIRTUALINPUT, CHỈ FIRECLICK + REMOTE

local p = game:GetService("Players").LocalPlayer
local c = p.Character or p.CharacterAdded:Wait()
local h = c:WaitForChild("Humanoid")
local r = c:WaitForChild("HumanoidRootPart")
local rs = game:GetService("ReplicatedStorage")
local ws = game:GetService("Workspace")
local uis = game:GetService("UserInputService")

local cfg = {
    farmN = false, farmB = false, spin = false, stat = false, reb = false,
    collect = false, skill = false, safe = true,
    speed = 85, jump = 85
}

local function tp(pos)
    if r then r.CFrame = CFrame.new(pos) end
end

local function click(det)
    if det and det:IsA("ClickDetector") then fireclickdetector(det) end
end

local function getN()
    local n, d = nil, 300
    for _, o in pairs(ws:GetDescendants()) do
        if o:IsA("Model") and o:FindFirstChild("Humanoid") and o:FindFirstChild("HumanoidRootPart") and o.Humanoid.Health > 0 then
            local nm = o.Name or ""
            if string.find(nm, "NPC") or string.find(nm, "Training") or string.find(nm, "Shinobi") then
                local dist = (o.HumanoidRootPart.Position - r.Position).Magnitude
                if dist < d then d = dist n = o end
            end
        end
    end
    return n
end

local function getB()
    local n, d = nil, 500
    for _, o in pairs(ws:GetDescendants()) do
        if o:IsA("Model") and o:FindFirstChild("Humanoid") and o:FindFirstChild("HumanoidRootPart") and o.Humanoid.Health > 0 then
            local nm = o.Name or ""
            if string.find(nm, "Boss") or string.find(nm, "Shindai") or string.find(nm, "Raion") then
                local dist = (o.HumanoidRootPart.Position - r.Position).Magnitude
                if dist < d then d = dist n = o end
            end
        end
    end
    return n
end

local function isNear()
    for _, pl in pairs(game:GetService("Players"):GetPlayers()) do
        if pl ~= p and pl.Character and pl.Character:FindFirstChild("HumanoidRootPart") then
            if (pl.Character.HumanoidRootPart.Position - r.Position).Magnitude < 100 then
                return true
            end
        end
    end
    return false
end

local function atk(t)
    if not t then return end
    local hrp = t:FindFirstChild("HumanoidRootPart")
    if hrp then
        local det = t:FindFirstChildWhichIsA("ClickDetector") or hrp:FindFirstChildWhichIsA("ClickDetector")
        if det then
            click(det)
        else
            local rem = rs:FindFirstChild("RemoteEvent")
            if rem then pcall(function() rem:FireServer("Attack", hrp.Position) end) end
        end
    end
end

local function skill()
    if not cfg.skill then return end
    local rem = rs:FindFirstChild("Skill") or rs:FindFirstChild("RemoteEvent")
    if rem then
        pcall(function()
            rem:FireServer("Z")
            rem:FireServer("X")
            rem:FireServer("C")
        end)
    end
end

local function coll()
    if not cfg.collect then return end
    for _, o in pairs(ws:GetDescendants()) do
        if o:IsA("Model") and o:FindFirstChildWhichIsA("ClickDetector") then
            local dist = (o.HumanoidRootPart and o.HumanoidRootPart.Position - r.Position).Magnitude or 999
            if dist < 50 then
                click(o:FindFirstChildWhichIsA("ClickDetector"))
            end
        end
    end
end

local function doSpin()
    local rem = rs:FindFirstChild("Spin")
    if rem then pcall(function() rem:FireServer(1) end) end
end

local function doStat()
    local rem = rs:FindFirstChild("Stat")
    if rem then
        pcall(function()
            rem:FireServer("Strength", 999)
            rem:FireServer("Speed", 999)
        end)
    else
        local s = p:FindFirstChild("Stats")
        if s then
            for _, v in pairs(s:GetChildren()) do
                if v:IsA("NumberValue") then v.Value = 99999 end
            end
        end
    end
end

local function doReb()
    local rem = rs:FindFirstChild("Rebirth")
    if rem then pcall(function() rem:FireServer() end) end
end

-- FARM NPC
spawn(function()
    while wait(0.2) do
        if cfg.farmN then
            if cfg.safe and isNear() then wait(1) continue end
            local n = getN()
            if n then
                tp(n.HumanoidRootPart.Position + Vector3.new(0, 0, 5))
                wait(0.2)
                for i = 1, 4 do
                    atk(n)
                    skill()
                    if cfg.collect then coll() end
                    wait(0.1)
                end
            else
                tp(Vector3.new(math.random(-300, 300), 50, math.random(-300, 300)))
                wait(0.5)
            end
        end
    end
end)

-- FARM BOSS
spawn(function()
    while wait(0.2) do
        if cfg.farmB then
            local b = getB()
            if b then
                tp(b.HumanoidRootPart.Position + Vector3.new(0, 0, 8))
                wait(0.3)
                while b and b.Humanoid and b.Humanoid.Health > 0 do
                    atk(b)
                    skill()
                    if cfg.collect then coll() end
                    wait(0.1)
                    local np = b.HumanoidRootPart.Position
                    if (np - r.Position).Magnitude > 15 then
                        tp(np + Vector3.new(0, 0, 8))
                    end
                end
                wait(2)
            else
                wait(3)
            end
        end
    end
end)

-- VÒNG LẶP PHỤ
spawn(function() while wait(5) do if cfg.spin then doSpin() end end end)
spawn(function() while wait(30) do if cfg.stat then doStat() end end end)
spawn(function() while wait(60) do if cfg.reb then doReb() end end end)

-- BẤT TỬ
h.Health = math.huge
h.MaxHealth = math.huge
h.BreakJointsOnDeath = false
h.Damaged:Connect(function(a) h.Health = h.Health + a end)

p.CharacterAdded:Connect(function(ch)
    wait(0.5)
    c = ch
    h = c:WaitForChild("Humanoid")
    r = c:WaitForChild("HumanoidRootPart")
    h.WalkSpeed = cfg.speed
    h.JumpPower = cfg.jump
    h.Health = math.huge
end)

-- GUI
local gui = Instance.new("ScreenGui")
gui.Name = "DeltaX_UI"
gui.ResetOnSpawn = false
gui.Parent = p:WaitForChild("PlayerGui")

local main = Instance.new("Frame")
main.Size = UDim2.new(0, 380, 0, 480)
main.Position = UDim2.new(0.5, -190, 0.15, 0)
main.BackgroundColor3 = Color3.fromRGB(8, 8, 20)
main.BorderSizePixel = 2
main.BorderColor3 = Color3.fromRGB(0, 180, 255)
main.Active = true
main.Draggable = true
main.Parent = gui

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 40)
title.Text = "⚡ DELTAX ULTIMATE"
title.TextColor3 = Color3.fromRGB(0, 220, 255)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold
title.TextScaled = true
title.Parent = main

local close = Instance.new("TextButton")
close.Size = UDim2.new(0, 30, 0, 30)
close.Position = UDim2.new(1, -35, 0, 5)
close.Text = "X"
close.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
close.TextColor3 = Color3.fromRGB(255, 255, 255)
close.Font = Enum.Font.Bold
close.TextScaled = true
close.Parent = main
close.MouseButton1Click:Connect(function() gui.Enabled = false end)

local function toggle(text, key, y, def)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(0.9, 0, 0, 42)
    f.Position = UDim2.new(0.05, 0, y, 0)
    f.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
    f.BorderSizePixel = 1
    f.BorderColor3 = Color3.fromRGB(80, 80, 120)
    f.Parent = main

    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(0.6, 0, 1, 0)
    l.Text = text
    l.TextColor3 = Color3.fromRGB(220, 220, 220)
    l.BackgroundTransparency = 1
    l.Font = Enum.Font.SourceSans
    l.TextScaled = true
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Parent = f

    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0.2, 0, 0.7, 0)
    b.Position = UDim2.new(0.75, 0, 0.15, 0)
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

toggle("🤖 Farm NPC", "farmN", 0.08, false)
toggle("👹 Farm Boss", "farmB", 0.20, false)
toggle("⚡ Spam Skill", "skill", 0.32, false)
toggle("🧹 Auto Collect", "collect", 0.44, false)
toggle("🌀 Auto Spin", "spin", 0.56, false)
toggle("💪 Auto Stat", "stat", 0.68, false)
toggle("♻️ Auto Rebirth", "reb", 0.80, false)

local btn1 = Instance.new("TextButton")
btn1.Size = UDim2.new(0.35, 0, 0, 35)
btn1.Position = UDim2.new(0.05, 0, 0.92, 0)
btn1.Text = "📌 Tele Rand"
btn1.BackgroundColor3 = Color3.fromRGB(30, 70, 130)
btn1.TextColor3 = Color3.fromRGB(255, 255, 255)
btn1.Font = Enum.Font.SourceSansBold
btn1.TextScaled = true
btn1.Parent = main
btn1.MouseButton1Click:Connect(function()
    tp(Vector3.new(math.random(-600, 600), 50, math.random(-600, 600)))
end)

local btn2 = Instance.new("TextButton")
btn2.Size = UDim2.new(0.35, 0, 0, 35)
btn2.Position = UDim2.new(0.55, 0, 0.92, 0)
btn2.Text = "🔄 Reset"
btn2.BackgroundColor3 = Color3.fromRGB(150, 30, 30)
btn2.TextColor3 = Color3.fromRGB(255, 255, 255)
btn2.Font = Enum.Font.SourceSansBold
btn2.TextScaled = true
btn2.Parent = main
btn2.MouseButton1Click:Connect(function() p:LoadCharacter() end)

uis.InputBegan:Connect(function(i, g)
    if g then return end
    if i.KeyCode == Enum.KeyCode.F1 then gui.Enabled = true end
    if i.KeyCode == Enum.KeyCode.F2 then gui.Enabled = false end
end)

print("[DELTAX] Script kích hoạt. F1 mở GUI, F2 đóng.")
