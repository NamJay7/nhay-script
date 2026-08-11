-- UI DEMO - CHỈ GIAO DIỆN, KHÔNG HÀNH ĐỘNG GÌ
-- THỬ CHẠY BẰNG LOADSTRING TRÊN DELTA X

local p = game:GetService("Players").LocalPlayer
local playerGui = p:WaitForChild("PlayerGui")

-- TẠO GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "DemoUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

-- FRAME CHÍNH (CÓ THỂ KÉO THẢ)
local main = Instance.new("Frame")
main.Size = UDim2.new(0, 400, 0, 500)
main.Position = UDim2.new(0.5, -200, 0.2, 0)
main.BackgroundColor3 = Color3.fromRGB(12, 12, 30)
main.BackgroundTransparency = 0.1
main.BorderSizePixel = 2
main.BorderColor3 = Color3.fromRGB(0, 200, 255)
main.Active = true
main.Draggable = true
main.Parent = screenGui

-- TIÊU ĐỀ
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 45)
title.Text = "⚡ NJAY UI DEMO"
title.TextColor3 = Color3.fromRGB(0, 220, 255)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold
title.TextScaled = true
title.Parent = main

-- NÚT ĐÓNG
local close = Instance.new("TextButton")
close.Size = UDim2.new(0, 30, 0, 30)
close.Position = UDim2.new(1, -35, 0, 5)
close.Text = "X"
close.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
close.TextColor3 = Color3.fromRGB(255, 255, 255)
close.Font = Enum.Font.Bold
close.TextScaled = true
close.Parent = main
close.MouseButton1Click:Connect(function() screenGui.Enabled = false end)

-- TẠO CÁC NÚT TOGGLE GIẢ (CHỈ HIỂN THỊ)
local function fakeToggle(text, y)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(0.9, 0, 0, 45)
    f.Position = UDim2.new(0.05, 0, y, 0)
    f.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
    f.BorderSizePixel = 1
    f.BorderColor3 = Color3.fromRGB(80, 80, 120)
    f.Parent = main

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.6, 0, 1, 0)
    label.Text = text .. " (DEMO)"
    label.TextColor3 = Color3.fromRGB(220, 220, 220)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.SourceSans
    label.TextScaled = true
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = f

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.2, 0, 0.7, 0)
    btn.Position = UDim2.new(0.75, 0, 0.15, 0)
    btn.Text = "OFF"
    btn.BackgroundColor3 = Color3.fromRGB(100, 40, 40)
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.SourceSansBold
    btn.TextScaled = true
    btn.Parent = f
    -- Chỉ chuyển đổi màu, không chức năng
    btn.MouseButton1Click:Connect(function()
        if btn.Text == "OFF" then
            btn.Text = "ON"
            btn.BackgroundColor3 = Color3.fromRGB(0, 130, 0)
        else
            btn.Text = "OFF"
            btn.BackgroundColor3 = Color3.fromRGB(100, 40, 40)
        end
    end)
end

fakeToggle("🤖 Farm NPC", 0.10)
fakeToggle("👹 Farm Boss", 0.22)
fakeToggle("⚡ Spam Skill", 0.34)
fakeToggle("🧹 Auto Collect", 0.46)
fakeToggle("🌀 Auto Spin", 0.58)
fakeToggle("💪 Auto Stat", 0.70)
fakeToggle("♻️ Auto Rebirth", 0.82)

-- NÚT PHỤ
local fakeBtn = Instance.new("TextButton")
fakeBtn.Size = UDim2.new(0.35, 0, 0, 35)
fakeBtn.Position = UDim2.new(0.05, 0, 0.92, 0)
fakeBtn.Text = "📌 Tele Rand (Demo)"
fakeBtn.BackgroundColor3 = Color3.fromRGB(30, 70, 130)
fakeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
fakeBtn.Font = Enum.Font.SourceSansBold
fakeBtn.TextScaled = true
fakeBtn.Parent = main
fakeBtn.MouseButton1Click:Connect(function()
    print("📌 Teleport demo - không có chức năng")
end)

local fakeBtn2 = Instance.new("TextButton")
fakeBtn2.Size = UDim2.new(0.35, 0, 0, 35)
fakeBtn2.Position = UDim2.new(0.55, 0, 0.92, 0)
fakeBtn2.Text = "🔄 Reset (Demo)"
fakeBtn2.BackgroundColor3 = Color3.fromRGB(150, 30, 30)
fakeBtn2.TextColor3 = Color3.fromRGB(255, 255, 255)
fakeBtn2.Font = Enum.Font.SourceSansBold
fakeBtn2.TextScaled = true
fakeBtn2.Parent = main
fakeBtn2.MouseButton1Click:Connect(function()
    print("🔄 Reset demo - không có chức năng")
end)

-- THÔNG BÁO
print("[UI DEMO] GUI đã hiển thị. F1/F2 không có tác dụng.") 
