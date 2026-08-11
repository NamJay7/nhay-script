-- =============================================
-- NJAY KEY SYSTEM v1.0 - TỐI ƯU DELTA X MOBILE
-- TÁC GIẢ: PALOFSC / NJAY
-- =============================================

-- CẤU HÌNH (SỬA THEO Ý BẠN)
local CORRECT_KEY = "NJAYKeySystem2026"                    -- Key đúng
local KEY_LINK = "https://example.com/getkey"              -- Link lấy key (nếu có)
local SCRIPT_URL = "https://raw.githubusercontent.com/NamJay7/nhay-script/main/loader.lua" -- Script chính
local SAVE_FILE = "NJAY_KeySave.json"                     -- Tên file lưu key

-- SERVICES
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

-- =============================================
-- CHECK SAVED KEY (24H AUTO-LOGIN)
-- =============================================
local function checkSavedKey()
    if readfile and isfile and isfile(SAVE_FILE) then
        local success, data = pcall(function()
            return HttpService:JSONDecode(readfile(SAVE_FILE))
        end)
        if success and data and data.key and data.expire then
            if data.key == CORRECT_KEY and os.time() < data.expire then
                return true
            end
        end
    end
    return false
end

-- LƯU KEY
local function saveKey(key)
    if writefile then
        local data = { key = key, expire = os.time() + 86400 }
        pcall(function()
            writefile(SAVE_FILE, HttpService:JSONEncode(data))
        end)
    end
end

-- TẢI SCRIPT CHÍNH
local function loadMain()
    local success, err = pcall(function()
        loadstring(game:HttpGet(SCRIPT_URL))()
    end)
    if not success then
        warn("[NJAY] Lỗi tải script: " .. tostring(err))
    end
end

-- NẾU KEY HỢP LỆ, CHẠY LUÔN
if checkSavedKey() then
    print("[NJAY] Key đã lưu hợp lệ. Tự động chạy script.")
    loadMain()
    return
end

-- =============================================
-- GIAO DIỆN KEY SYSTEM (NẾU CHƯA CÓ KEY)
-- =============================================

-- XÓA UI CŨ NẾU CÓ
if CoreGui:FindFirstChild("NJAY_KeyUI") then
    CoreGui.NJAY_KeyUI:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "NJAY_KeyUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = CoreGui or Players.LocalPlayer:WaitForChild("PlayerGui")

-- MAIN FRAME
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 380, 0, 250)
MainFrame.Position = UDim2.new(0.5, -190, 0.5, -125)
MainFrame.BackgroundColor3 = Color3.fromRGB(12, 12, 28)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

local Corner = Instance.new("UICorner", MainFrame)
Corner.CornerRadius = UDim.new(0, 16)

local Stroke = Instance.new("UIStroke", MainFrame)
Stroke.Color = Color3.fromRGB(0, 180, 255)
Stroke.Thickness = 1.5
Stroke.Transparency = 0.3

-- TITLE
local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, 0, 0, 45)
Title.Position = UDim2.new(0, 0, 0, 10)
Title.BackgroundTransparency = 1
Title.Font = Enum.Font.GothamBold
Title.Text = "⚡ NJAY KEY SYSTEM"
Title.TextColor3 = Color3.fromRGB(0, 220, 255)
Title.TextSize = 20
Title.TextScaled = true

local Sub = Instance.new("TextLabel", MainFrame)
Sub.Size = UDim2.new(1, 0, 0, 22)
Sub.Position = UDim2.new(0, 0, 0, 52)
Sub.BackgroundTransparency = 1
Sub.Font = Enum.Font.Gotham
Sub.Text = "Nhập key để kích hoạt script"
Sub.TextColor3 = Color3.fromRGB(150, 150, 180)
Sub.TextSize = 13

-- INPUT
local InputBox = Instance.new("Frame", MainFrame)
InputBox.Size = UDim2.new(0.85, 0, 0, 40)
InputBox.Position = UDim2.new(0.075, 0, 0.32, 0)
InputBox.BackgroundColor3 = Color3.fromRGB(25, 25, 40)
InputBox.BorderSizePixel = 0

local InputCorner = Instance.new("UICorner", InputBox)
InputCorner.CornerRadius = UDim.new(0, 8)

local InputStroke = Instance.new("UIStroke", InputBox)
InputStroke.Color = Color3.fromRGB(60, 60, 90)
InputStroke.Thickness = 1

local KeyInput = Instance.new("TextBox", InputBox)
KeyInput.Size = UDim2.new(1, -16, 1, 0)
KeyInput.Position = UDim2.new(0, 8, 0, 0)
KeyInput.BackgroundTransparency = 1
KeyInput.Font = Enum.Font.Gotham
KeyInput.PlaceholderText = "Nhập key tại đây..."
KeyInput.PlaceholderColor3 = Color3.fromRGB(100, 100, 130)
KeyInput.Text = ""
KeyInput.TextColor3 = Color3.fromRGB(255, 255, 255)
KeyInput.TextSize = 14
KeyInput.ClearTextOnFocus = false

-- BUTTON CONTAINER
local BtnContainer = Instance.new("Frame", MainFrame)
BtnContainer.Size = UDim2.new(0.85, 0, 0, 40)
BtnContainer.Position = UDim2.new(0.075, 0, 0.54, 0)
BtnContainer.BackgroundTransparency = 1

-- SUBMIT BUTTON
local SubmitBtn = Instance.new("TextButton", BtnContainer)
SubmitBtn.Size = UDim2.new(0.48, 0, 1, 0)
SubmitBtn.Position = UDim2.new(0, 0, 0, 0)
SubmitBtn.BackgroundColor3 = Color3.fromRGB(0, 140, 255)
SubmitBtn.Font = Enum.Font.GothamBold
SubmitBtn.Text = "KÍCH HOẠT"
SubmitBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
SubmitBtn.TextSize = 13
SubmitBtn.AutoButtonColor = false

local SubmitCorner = Instance.new("UICorner", SubmitBtn)
SubmitCorner.CornerRadius = UDim.new(0, 8)

local BtnGrad = Instance.new("UIGradient", SubmitBtn)
BtnGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 140, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(80, 50, 255))
})

-- GET KEY BUTTON
local GetKeyBtn = Instance.new("TextButton", BtnContainer)
GetKeyBtn.Size = UDim2.new(0.48, 0, 1, 0)
GetKeyBtn.Position = UDim2.new(0.52, 0, 0, 0)
GetKeyBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 55)
GetKeyBtn.Font = Enum.Font.GothamBold
GetKeyBtn.Text = "LẤY KEY 🔑"
GetKeyBtn.TextColor3 = Color3.fromRGB(200, 200, 230)
GetKeyBtn.TextSize = 13
GetKeyBtn.AutoButtonColor = false

local GetKeyCorner = Instance.new("UICorner", GetKeyBtn)
GetKeyCorner.CornerRadius = UDim.new(0, 8)

local GetKeyStroke = Instance.new("UIStroke", GetKeyBtn)
GetKeyStroke.Color = Color3.fromRGB(80, 80, 120)
GetKeyStroke.Thickness = 1

-- STATUS LABEL
local Status = Instance.new("TextLabel", MainFrame)
Status.Size = UDim2.new(0.85, 0, 0, 22)
Status.Position = UDim2.new(0.075, 0, 0.80, 0)
Status.BackgroundTransparency = 1
Status.Font = Enum.Font.GothamMedium
Status.Text = ""
Status.TextColor3 = Color3.fromRGB(255, 255, 255)
Status.TextSize = 12

-- =============================================
-- ANIMATIONS & LOGIC
-- =============================================

-- HOVER EFFECTS
SubmitBtn.MouseEnter:Connect(function()
    TweenService:Create(SubmitBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(30, 160, 255)}):Play()
end)
SubmitBtn.MouseLeave:Connect(function()
    TweenService:Create(SubmitBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(0, 140, 255)}):Play()
end)

GetKeyBtn.MouseEnter:Connect(function()
    TweenService:Create(GetKeyBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(50, 50, 75)}):Play()
end)
GetKeyBtn.MouseLeave:Connect(function()
    TweenService:Create(GetKeyBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(35, 35, 55)}):Play()
end)

-- FOCUS INPUT
KeyInput.Focused:Connect(function()
    TweenService:Create(InputStroke, TweenInfo.new(0.2), {Color = Color3.fromRGB(0, 180, 255)}):Play()
end)
KeyInput.FocusLost:Connect(function()
    TweenService:Create(InputStroke, TweenInfo.new(0.2), {Color = Color3.fromRGB(60, 60, 90)}):Play()
end)

-- GET KEY
GetKeyBtn.MouseButton1Click:Connect(function()
    if setclipboard then
        setclipboard(KEY_LINK)
        Status.TextColor3 = Color3.fromRGB(0, 220, 180)
        Status.Text = "✅ Đã sao chép link lấy key!"
    else
        Status.TextColor3 = Color3.fromRGB(255, 200, 80)
        Status.Text = "🔗 Link: " .. KEY_LINK
    end
end)

-- SHAKE EFFECT
local function shake()
    local orig = UDim2.new(0.5, -190, 0.5, -125)
    local off = 8
    for _ = 1, 3 do
        for _, x in ipairs({off, -off, off/2, -off/2}) do
            MainFrame.Position = orig + UDim2.new(0, x, 0, 0)
            task.wait(0.04)
        end
    end
    MainFrame.Position = orig
end

-- SUBMIT
SubmitBtn.MouseButton1Click:Connect(function()
    local input = KeyInput.Text
    if input == CORRECT_KEY then
        -- ĐÚNG KEY
        saveKey(input)
        Status.TextColor3 = Color3.fromRGB(80, 255, 120)
        Status.Text = "✅ Key chính xác! Đang tải script..."
        TweenService:Create(Stroke, TweenInfo.new(0.3), {Color = Color3.fromRGB(80, 255, 120)}):Play()
        task.wait(1)
        -- ẨN UI
        TweenService:Create(MainFrame, TweenInfo.new(0.4, Enum.EasingStyle.Back), {Size = UDim2.new(0, 0, 0, 0)}):Play()
        task.wait(0.4)
        ScreenGui:Destroy()
        loadMain()
    else
        -- SAI KEY
        Status.TextColor3 = Color3.fromRGB(255, 70, 70)
        Status.Text = "❌ Key sai! Vui lòng thử lại."
        TweenService:Create(InputStroke, TweenInfo.new(0.2), {Color = Color3.fromRGB(255, 60, 60)}):Play()
        shake()
        task.wait(0.3)
        TweenService:Create(InputStroke, TweenInfo.new(0.2), {Color = Color3.fromRGB(60, 60, 90)}):Play()
    end
end)

print("[NJAY] Key System sẵn sàng. F1/F2 không dùng trong UI này.")
