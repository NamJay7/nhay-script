--[[
    SHINDO LIFE PRO MOBILE v4.0 – Hoàn thiện tất cả yêu cầu
    - Menu toggle hoạt động ổn định (dùng Activated, debounce)
    - Auto Farm Level: đánh quái tự do (không quest)
    - Auto Quest: nhận quest chiến đấu (!), tự động accept, farm, nộp (không nhận quest ngôi sao)
    - Auto Boss: săn boss, spam skill
    - Auto Rank Up: tự động rank khi có thể
    - Auto Scroll: thu thập scroll
    - Tùy chọn Spam Skill: nhập tên skill để spam (mặc định "Skill1")
    - Fly và Noclip đã bỏ theo yêu cầu
    - Giao diện xanh biển nhạt, tối ưu cảm ứng.
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

-- ================== TÌM REMOTE ==================
local function findRemote(name)
    for _, v in ipairs(ReplicatedStorage:GetDescendants()) do
        if v:IsA("RemoteEvent") and v.Name == name then return v end
    end
    return nil
end
local damageRemote = findRemote("Damage") or findRemote("CastSpell") or findRemote("Attack")
local rankUpRemote = findRemote("RankUp") or findRemote("Promote") or findRemote("Evolve")

-- ================== BIẾN TOÀN CỤC ==================
local autoFarmEnabled = false
local autoQuestEnabled = false
local autoBossEnabled = false
local autoRankEnabled = false
local autoScrollEnabled = false
local farmRange = 200
local targetBoss = "Tất cả"
local questFarmDuration = 15 -- thời gian farm mỗi quest (giây)
local skillToSpam = "Skill1" -- tên skill mặc định

-- ================== HÀM PHỤ TRỢ ==================
local function teleportToCFrame(cf)
    local c = LocalPlayer.Character
    if c and c:FindFirstChild("HumanoidRootPart") then
        c.HumanoidRootPart.CFrame = cf
    end
end

local function findNearestEnemy(range, specificName)
    local char = LocalPlayer.Character
    if not char then return nil end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end
    local nearest, minDist = nil, range or 200
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") and obj ~= char then
            local hum = obj:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then
                local root = obj:FindFirstChild("HumanoidRootPart")
                if root then
                    if specificName and not obj.Name:lower():find(specificName:lower()) then
                        -- skip
                    else
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

local function findQuestNPC()
    -- Tìm NPC có dấu "!" (quest chính), bỏ qua dấu sao (*) hoặc biểu tượng khác
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") and obj.Name:lower():find("npc") then
            local hum = obj:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then
                local head = obj:FindFirstChild("Head")
                if head then
                    for _, gui in ipairs(head:GetChildren()) do
                        if gui:IsA("BillboardGui") then
                            local tl = gui:FindFirstChild("TextLabel") or gui:FindFirstChild("ImageLabel")
                            if tl then
                                -- Kiểm tra nếu là dấu "!" (có thể là chữ hoặc hình ảnh)
                                if tl:IsA("TextLabel") and tl.Text == "!" then
                                    return obj
                                elseif tl:IsA("ImageLabel") and tl.Image:find("exclamation") then
                                    return obj
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    -- Dự phòng: tìm model có tên chứa "quest"
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") and obj.Name:lower():find("quest") then
            local hum = obj:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then
                -- tránh NPC có dấu sao
                local head = obj:FindFirstChild("Head")
                if head then
                    local hasStar = false
                    for _, gui in ipairs(head:GetChildren()) do
                        if gui:IsA("BillboardGui") and gui:FindFirstChild("ImageLabel") then
                            if gui.ImageLabel.Image:find("star") then hasStar = true break end
                        end
                    end
                    if not hasStar then return obj end
                else
                    return obj
                end
            end
        end
    end
    return nil
end

local function findScroll()
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") and (obj.Name:lower():find("scroll") or obj.Name:lower():find("paper")) then
            return obj
        end
    end
    return nil
end

local function attackTarget(target, skillName)
    if not target then return end
    local root = target:FindFirstChild("HumanoidRootPart")
    if not root then return end
    skillName = skillName or skillToSpam
    if damageRemote then
        pcall(function()
            damageRemote:FireServer(target, skillName)
        end)
    else
        local pos, onScreen = Workspace.CurrentCamera:WorldToViewportPoint(root.Position)
        if onScreen then
            VirtualInputManager:SendMouseButtonEvent(pos.X, pos.Y, 0, true, game, 1)
            task.wait(0.05)
            VirtualInputManager:SendMouseButtonEvent(pos.X, pos.Y, 0, false, game, 1)
        end
    end
end

local function findAndClickButton(guiParent, buttonText, maxDepth)
    -- Tìm đệ quy TextButton hoặc ImageButton có Text chứa buttonText (không phân biệt hoa thường)
    local function search(obj, depth)
        if depth > (maxDepth or 10) then return nil end
        if obj:IsA("TextButton") or obj:IsA("ImageButton") then
            if obj:IsA("TextButton") and obj.Text:lower():find(buttonText:lower()) then
                return obj
            elseif obj.Name:lower():find(buttonText:lower()) then
                return obj
            end
        end
        for _, child in ipairs(obj:GetChildren()) do
            local found = search(child, depth+1)
            if found then return found end
        end
        return nil
    end
    return search(guiParent, 0)
end

-- ================== CHỨC NĂNG AUTO FARM LEVEL ==================
local farmThread
function toggleAutoFarm()
    autoFarmEnabled = not autoFarmEnabled
    if autoFarmEnabled then
        if autoQuestEnabled then toggleAutoQuest() end -- tắt quest nếu bật
        farmThread = task.spawn(function()
            while autoFarmEnabled do
                local target = findNearestEnemy(farmRange)
                if target then
                    teleportToCFrame(target.HumanoidRootPart.CFrame + Vector3.new(0,3,0))
                    attackTarget(target, skillToSpam)
                end
                task.wait(0.2)
            end
        end)
    else
        if farmThread then task.cancel(farmThread) end
    end
end

-- ================== AUTO QUEST (CHIẾN ĐẤU) ==================
local questThread
function toggleAutoQuest()
    autoQuestEnabled = not autoQuestEnabled
    if autoQuestEnabled then
        if autoFarmEnabled then toggleAutoFarm() end
        questThread = task.spawn(function()
            while autoQuestEnabled do
                local npc = findQuestNPC()
                if npc then
                    -- Đến NPC
                    teleportToCFrame(npc.HumanoidRootPart.CFrame + Vector3.new(0,3,5))
                    task.wait(0.5)
                    -- Click vào NPC để mở hội thoại
                    local npcHead = npc:FindFirstChild("Head")
                    if npcHead then
                        local pos = Workspace.CurrentCamera:WorldToViewportPoint(npcHead.Position)
                        VirtualInputManager:SendMouseButtonEvent(pos.X, pos.Y, 0, true, game, 1)
                        task.wait(0.1)
                        VirtualInputManager:SendMouseButtonEvent(pos.X, pos.Y, 0, false, game, 1)
                    end
                    task.wait(1) -- chờ GUI quest hiện ra
                    -- Tìm nút Accept trong PlayerGui
                    local acceptBtn = findAndClickButton(LocalPlayer.PlayerGui, "accept", 8) or
                                      findAndClickButton(LocalPlayer.PlayerGui, "yes", 8) or
                                      findAndClickButton(LocalPlayer.PlayerGui, "ok", 8)
                    if acceptBtn then
                        -- Click nút Accept
                        local btnPos = acceptBtn.AbsolutePosition + acceptBtn.AbsoluteSize/2
                        VirtualInputManager:SendMouseButtonEvent(btnPos.X, btnPos.Y, 0, true, game, 1)
                        task.wait(0.1)
                        VirtualInputManager:SendMouseButtonEvent(btnPos.X, btnPos.Y, 0, false, game, 1)
                    end
                    task.wait(1)
                    -- Farm quái (tìm kẻ thù xung quanh, có thể đánh dấu bởi quest)
                    local startTime = tick()
                    while tick() - startTime < questFarmDuration and autoQuestEnabled do
                        local enemy = findNearestEnemy(150) -- tầm trung bình
                        if enemy then
                            teleportToCFrame(enemy.HumanoidRootPart.CFrame + Vector3.new(0,3,0))
                            attackTarget(enemy, skillToSpam)
                        end
                        task.wait(0.25)
                    end
                    -- Quay lại NPC
                    teleportToCFrame(npc.HumanoidRootPart.CFrame + Vector3.new(0,3,5))
                    task.wait(0.5)
                    -- Click NPC để hoàn thành
                    if npcHead then
                        local pos = Workspace.CurrentCamera:WorldToViewportPoint(npcHead.Position)
                        VirtualInputManager:SendMouseButtonEvent(pos.X, pos.Y, 0, true, game, 1)
                        task.wait(0.1)
                        VirtualInputManager:SendMouseButtonEvent(pos.X, pos.Y, 0, false, game, 1)
                    end
                    task.wait(1)
                    -- Tìm nút Complete/Claim
                    local completeBtn = findAndClickButton(LocalPlayer.PlayerGui, "complete", 8) or
                                        findAndClickButton(LocalPlayer.PlayerGui, "claim", 8) or
                                        findAndClickButton(LocalPlayer.PlayerGui, "finish", 8)
                    if completeBtn then
                        local btnPos = completeBtn.AbsolutePosition + completeBtn.AbsoluteSize/2
                        VirtualInputManager:SendMouseButtonEvent(btnPos.X, btnPos.Y, 0, true, game, 1)
                        task.wait(0.1)
                        VirtualInputManager:SendMouseButtonEvent(btnPos.X, btnPos.Y, 0, false, game, 1)
                    end
                    task.wait(2) -- chờ nhận thưởng
                else
                    task.wait(3) -- không có NPC, nghỉ
                end
            end
        end)
    else
        if questThread then task.cancel(questThread) end
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
                    local root = boss:FindFirstChild("HumanoidRootPart")
                    if root then
                        teleportToCFrame(root.CFrame + Vector3.new(0,5,0))
                        -- Spam skill mạnh
                        for _ = 1, 4 do
                            attackTarget(boss, skillToSpam) -- dùng skill người dùng chọn
                            task.wait(0.15)
                        end
                    end
                end
                task.wait(0.5)
            end
        end)
    else
        if bossThread then task.cancel(bossThread) end
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
                    pcall(function() rankUpRemote:FireServer() end)
                else
                    -- Tìm nút Rank Up trong PlayerGui
                    local rankBtn = findAndClickButton(LocalPlayer.PlayerGui, "rank", 8) or
                                    findAndClickButton(LocalPlayer.PlayerGui, "evolve", 8) or
                                    findAndClickButton(LocalPlayer.PlayerGui, "promote", 8)
                    if rankBtn then
                        local pos = rankBtn.AbsolutePosition + rankBtn.AbsoluteSize/2
                        VirtualInputManager:SendMouseButtonEvent(pos.X, pos.Y, 0, true, game, 1)
                        task.wait(0.1)
                        VirtualInputManager:SendMouseButtonEvent(pos.X, pos.Y, 0, false, game, 1)
                    end
                end
                task.wait(10)
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
                local scroll = findScroll()
                if scroll then
                    local part = scroll:FindFirstChild("Part") or scroll:FindFirstChild("Handle")
                    if part then
                        teleportToCFrame(part.CFrame)
                        firetouchinterest(LocalPlayer.Character.HumanoidRootPart, part, 0)
                        task.wait(0.2)
                    end
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
mainGui.Name = "ShindoProV4"
mainGui.ResetOnSpawn = false
mainGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

-- Nút Toggle chính (sử dụng Activated, debounce)
local toggleBtn = Instance.new("TextButton")
toggleBtn.Size = UDim2.new(0, 70, 0, 70)
toggleBtn.Position = UDim2.new(0, 10, 0.5, -35)
toggleBtn.BackgroundColor3 = Color3.fromRGB(135, 206, 235)
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
local debounceTime = 0

local function toggleGUI()
    local now = tick()
    if now - debounceTime < 0.3 then return end -- chống double tap
    debounceTime = now
    guiVisible = not guiVisible
    if mainFrame then mainFrame.Visible = guiVisible end
    toggleBtn.Text = guiVisible and "−" or "+"
end

toggleBtn.Activated:Connect(toggleGUI) -- sự kiện tin cậy nhất trên mobile

-- Khung chính
mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 300, 0, 420)
mainFrame.Position = UDim2.new(0, 10, 0.5, -210)
mainFrame.BackgroundColor3 = Color3.fromRGB(230, 240, 250)
mainFrame.BorderSizePixel = 0
mainFrame.Visible = false
mainFrame.ClipsDescendants = true
mainFrame.Parent = mainGui
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0,12)

-- Tiêu đề
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1,0,0,35)
title.BackgroundColor3 = Color3.fromRGB(173,216,230)
title.TextColor3 = Color3.new(0,0,0.3)
title.Font = Enum.Font.SourceSansBold
title.Text = "Shindo Pro v4.0"
title.TextSize = 16
title.Parent = mainFrame

-- Vùng nội dung
local content = Instance.new("Frame")
content.Size = UDim2.new(1,0,1,-35)
content.Position = UDim2.new(0,0,0,35)
content.BackgroundTransparency = 1
content.Parent = mainFrame

-- Hàm tạo nút toggle chức năng
local function addToggleButton(text, y, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -20, 0, 35)
    btn.Position = UDim2.new(0, 10, 0, y)
    btn.BackgroundColor3 = Color3.fromRGB(100,149,237)
    btn.TextColor3 = Color3.new(1,1,1)
    btn.Font = Enum.Font.SourceSans
    btn.Text = text .. ": OFF"
    btn.TextSize = 14
    btn.BorderSizePixel = 0
    btn.Parent = content
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0,6)
    local enabled = false
    btn.Activated:Connect(function()
        enabled = not enabled
        btn.Text = text .. ": " .. (enabled and "ON" or "OFF")
        btn.BackgroundColor3 = enabled and Color3.fromRGB(34,139,34) or Color3.fromRGB(100,149,237)
        callback(enabled)
    end)
    return btn
end

-- Các nút chức năng
addToggleButton("Auto Farm Level", 10, function(on) toggleAutoFarm() end)
addToggleButton("Auto Quest (!)", 50, function(on) toggleAutoQuest() end)
addToggleButton("Auto Boss", 90, function(on) toggleAutoBoss() end)
addToggleButton("Auto Rank Up", 130, function(on) toggleAutoRank() end)
addToggleButton("Auto Scroll", 170, function(on) toggleAutoScroll() end)

-- Cài đặt Spam Skill
local skillLabel = Instance.new("TextLabel")
skillLabel.Size = UDim2.new(1, -20, 0, 25)
skillLabel.Position = UDim2.new(0, 10, 0, 215)
skillLabel.BackgroundTransparency = 1
skillLabel.TextColor3 = Color3.new(0,0,0.3)
skillLabel.Font = Enum.Font.SourceSans
skillLabel.Text = "Tên Skill Spam:"
skillLabel.TextSize = 14
skillLabel.Parent = content

local skillInput = Instance.new("TextBox")
skillInput.Size = UDim2.new(1, -20, 0, 30)
skillInput.Position = UDim2.new(0, 10, 0, 240)
skillInput.BackgroundColor3 = Color3.fromRGB(100,149,237)
skillInput.TextColor3 = Color3.new(1,1,1)
skillInput.PlaceholderText = "VD: Skill1, Rasengan..."
skillInput.Text = skillToSpam
skillInput.Font = Enum.Font.SourceSans
skillInput.TextSize = 14
skillInput.Parent = content
skillInput.FocusLost:Connect(function()
    skillToSpam = skillInput.Text ~= "" and skillInput.Text or "Skill1"
end)

-- Phạm vi Farm
local rangeLabel = Instance.new("TextLabel")
rangeLabel.Size = UDim2.new(1, -20, 0, 25)
rangeLabel.Position = UDim2.new(0, 10, 0, 280)
rangeLabel.BackgroundTransparency = 1
rangeLabel.TextColor3 = Color3.new(0,0,0.3)
rangeLabel.Font = Enum.Font.SourceSans
rangeLabel.Text = "Phạm vi Farm:"
rangeLabel.TextSize = 14
rangeLabel.Parent = content

local rangeInput = Instance.new("TextBox")
rangeInput.Size = UDim2.new(1, -20, 0, 30)
rangeInput.Position = UDim2.new(0, 10, 0, 305)
rangeInput.BackgroundColor3 = Color3.fromRGB(100,149,237)
rangeInput.TextColor3 = Color3.new(1,1,1)
rangeInput.PlaceholderText = "200"
rangeInput.Text = tostring(farmRange)
rangeInput.Font = Enum.Font.SourceSans
rangeInput.TextSize = 14
rangeInput.Parent = content
rangeInput.FocusLost:Connect(function()
    farmRange = tonumber(rangeInput.Text) or 200
end)

-- Chọn Boss
local bossLabel = Instance.new("TextLabel")
bossLabel.Size = UDim2.new(1, -20, 0, 25)
bossLabel.Position = UDim2.new(0, 10, 0, 345)
bossLabel.BackgroundTransparency = 1
bossLabel.TextColor3 = Color3.new(0,0,0.3)
bossLabel.Font = Enum.Font.SourceSans
bossLabel.Text = "Chọn Boss:"
bossLabel.TextSize = 14
bossLabel.Parent = content

local bossDropdown = Instance.new("TextButton")
bossDropdown.Size = UDim2.new(1, -20, 0, 30)
bossDropdown.Position = UDim2.new(0, 10, 0, 370)
bossDropdown.BackgroundColor3 = Color3.fromRGB(100,149,237)
bossDropdown.TextColor3 = Color3.new(1,1,1)
bossDropdown.Font = Enum.Font.SourceSans
bossDropdown.Text = "Tất cả"
bossDropdown.TextSize = 14
bossDropdown.Parent = content
local bossList = {"Tất cả", "Akuma", "Tengoku", "Renshiki", "Forge Boss"}
local bossIndex = 1
bossDropdown.Activated:Connect(function()
    bossIndex = bossIndex % #bossList + 1
    targetBoss = bossList[bossIndex]
    bossDropdown.Text = targetBoss
end)

-- Thông báo trạng thái
local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, 0, 0, 20)
statusLabel.Position = UDim2.new(0, 0, 1, -20)
statusLabel.BackgroundColor3 = Color3.fromRGB(173,216,230)
statusLabel.TextColor3 = Color3.new(0,0,0.3)
statusLabel.Font = Enum.Font.SourceSans
statusLabel.Text = "Đã sẵn sàng"
statusLabel.TextSize = 12
statusLabel.Parent = mainFrame

print("Shindo Pro v4.0 loaded! Bấm nút '+' để mở menu.")
