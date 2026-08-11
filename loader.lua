--[[
    MODERN MENU – Shindo Pro Style
    - Nút "+" bo góc, màu xanh dương gradient (giả lập), đặt góc trái.
    - Menu chính màu tối (xám đen), trong suốt nhẹ, viền bo, tiêu đề sáng.
    - Các nút chức năng với hiệu ứng hover đổi màu (nếu có thể, nhưng chỉ giả lập static).
    - Tất cả sự kiện được xử lý an toàn để đảm bảo hiển thị.
]]

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")

local mainGui = Instance.new("ScreenGui")
mainGui.Name = "ModernMenu"
mainGui.ResetOnSpawn = false
mainGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

-- Nút toggle chính (góc trái, xanh dương)
local toggleBtn = Instance.new("ImageButton")
toggleBtn.Size = UDim2.new(0, 60, 0, 60)
toggleBtn.Position = UDim2.new(0, 10, 0.5, -30)
toggleBtn.BackgroundColor3 = Color3.fromRGB(0, 120, 215) -- xanh dương hiện đại
toggleBtn.BorderSizePixel = 0
toggleBtn.Image = "rbxassetid://0"
toggleBtn.ImageTransparency = 1.0
toggleBtn.Active = true
toggleBtn.AutoButtonColor = false
toggleBtn.Parent = mainGui
Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0, 15) -- bo tròn hơn

local toggleIcon = Instance.new("TextLabel")
toggleIcon.Size = UDim2.new(1,0,1,0)
toggleIcon.BackgroundTransparency = 1
toggleIcon.Text = "+"
toggleIcon.TextColor3 = Color3.new(1,1,1)
toggleIcon.Font = Enum.Font.SourceSansBold
toggleIcon.TextSize = 32
toggleIcon.TextStrokeTransparency = 0.8
toggleIcon.Parent = toggleBtn

-- Khung menu hiện đại
local menuFrame = Instance.new("Frame")
menuFrame.Size = UDim2.new(0, 280, 0, 350)
menuFrame.Position = UDim2.new(0, 100, 0.5, -175)
menuFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
menuFrame.BorderSizePixel = 0
menuFrame.BackgroundTransparency = 0.05 -- trong suốt nhẹ
menuFrame.Visible = false
menuFrame.Parent = mainGui
Instance.new("UICorner", menuFrame).CornerRadius = UDim.new(0, 18)
-- Viền sáng nhẹ
local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(100, 149, 237)
stroke.Thickness = 1.5
stroke.Parent = menuFrame

-- Thanh tiêu đề
local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1,0,0,40)
titleBar.BackgroundColor3 = Color3.fromRGB(70, 130, 200)
titleBar.BorderSizePixel = 0
titleBar.Parent = menuFrame
Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0, 18)

local titleText = Instance.new("TextLabel")
titleText.Size = UDim2.new(1,0,1,0)
titleText.BackgroundTransparency = 1
titleText.Text = "Shindo Pro v1.0"
titleText.TextColor3 = Color3.new(1,1,1)
titleText.Font = Enum.Font.SourceSansBold
titleText.TextSize = 18
titleText.Parent = titleBar

-- Nội dung
local content = Instance.new("Frame")
content.Size = UDim2.new(1,0,1,-40)
content.Position = UDim2.new(0,0,0,40)
content.BackgroundTransparency = 1
content.Parent = menuFrame

-- Một vài nút chức năng giả để thấy giao diện
local function addButton(text, y)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -30, 0, 40)
    btn.Position = UDim2.new(0, 15, 0, y)
    btn.BackgroundColor3 = Color3.fromRGB(60, 65, 75)
    btn.TextColor3 = Color3.new(1,1,1)
    btn.Font = Enum.Font.SourceSans
    btn.Text = text
    btn.TextSize = 14
    btn.BorderSizePixel = 0
    btn.Parent = content
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 10)
    -- Thêm viền nhẹ
    local btnStroke = Instance.new("UIStroke")
    btnStroke.Color = Color3.fromRGB(120, 140, 190)
    btnStroke.Thickness = 1
    btnStroke.Parent = btn
end

addButton("Auto Farm Level", 10)
addButton("Auto Boss", 60)
addButton("ESP", 110)
addButton("Settings", 160)

-- Hành vi toggle menu (nhiều sự kiện)
local menuVisible = false
local function toggleMenu()
    menuVisible = not menuVisible
    menuFrame.Visible = menuVisible
    toggleIcon.Text = menuVisible and "×" or "+"
end

toggleBtn.MouseButton1Click:Connect(toggleMenu)
toggleBtn.Activated:Connect(toggleMenu)

-- Phòng hờ: nếu nhấn trực tiếp lên màn hình (touch) trúng vùng nút, nhưng vì đã có ImageButton, có thể không cần. Tuy nhiên trên một số thiết bị, sự kiện Touch bị chặn bởi game. Cứ thêm cho chắc:
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.UserInputType == Enum.UserInputType.Touch then
        local pos = input.Position
        local absPos = toggleBtn.AbsolutePosition
        local absSize = toggleBtn.AbsoluteSize
        if pos.X >= absPos.X and pos.X <= absPos.X + absSize.X and
           pos.Y >= absPos.Y and pos.Y <= absPos.Y + absSize.Y then
            toggleMenu()
        end
    end
end)

print("Modern menu ready. Tap the blue button.")
