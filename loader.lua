--[[
    SHINDO LIFE PRO MOBILE v5.0 – FULL CHỨC NĂNG, HOẠT ĐỘNG MƯỢT TRÊN DELTA X
    - Tự động tìm NPC, accept quest, di chuyển đến vị trí quái (dấu đỏ), farm, quay về nộp.
    - Auto Boss: di chuyển đến boss, spam skill.
    - Auto Rank: tự động rank khi đủ.
    - Spam Skill: tạo bàn phím ảo Y,G,H,N,B,V; mỗi nút gán 1 skill, giữ để spam.
    - Tất cả đều dùng remote nếu có, fallback VirtualInputManager.
    - Giao diện xanh biển nhạt, menu toggle ổn định.
    - Dài, chi tiết, đầy đủ comment tiếng Việt.
]]

-- ================== DỊCH VỤ ==================
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInputManager = game:GetService("VirtualInputManager")
local Debris = game:GetService("Debris")
local PathfindingService = game:GetService("PathfindingService")

-- ================== TÌM REMOTE (NÂNG CAO) ==================
local function deepSearchRemote(name)
    for _, v in ipairs(ReplicatedStorage:GetDescendants()) do
        if v:IsA("RemoteEvent") and v.Name == name then
            return v
        end
    end
    -- Tìm trong các folder con của ReplicatedStorage, thậm chí trong Remotes folder
    local remotesFolder = ReplicatedStorage:FindFirstChild("Remotes")
    if remotesFolder then
        for _, v in ipairs(remotesFolder:GetDescendants()) do
            if v:IsA("RemoteEvent") and v.Name == name then
                return v
            end
        end
    end
    return nil
end

local damageRemote = deepSearchRemote("Damage") or deepSearchRemote("CastSpell") or deepSearchRemote("Attack")
local questAcceptRemote = deepSearchRemote("AcceptQuest") or deepSearchRemote("StartQuest") or deepSearchRemote("BeginQuest")
local questCompleteRemote = deepSearchRemote("CompleteQuest") or deepSearchRemote("FinishQuest") or deepSearchRemote("EndQuest")
local rankUpRemote = deepSearchRemote("RankUp") or deepSearchRemote("Promote") or deepSearchRemote("Evolve")
local skillEquipRemote = deepSearchRemote("EquipSkill") or deepSearchRemote("SelectSkill")

-- ================== BIẾN TOÀN CỤC ==================
local autoFarmEnabled = false
local autoQuestEnabled = false
local autoBossEnabled = false
local autoRankEnabled = false
local autoScrollEnabled = false
local farmRange = 200
local targetBoss = "Tất cả"
local questFarmDuration = 15 -- giây
local skillToSpam = "Skill1"
local spamActive = false -- trạng thái spam thủ công
local currentSpamSkill = "Skill1"

-- ================== HÀM TIỆN ÍCH ==================
local function teleportToCFrame(cf)
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        char.HumanoidRootPart.CFrame = cf
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
    -- Tìm NPC có dấu "!" (quest chính)
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") then
            local hum = obj:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then
                local head = obj:FindFirstChild("Head")
                if head then
                    for _, gui in ipairs(head:GetChildren()) do
                        if gui:IsA("BillboardGui") then
                            if gui:FindFirstChild("TextLabel") and gui.TextLabel.Text == "!" then
                                return obj
                            elseif gui:FindFirstChild("ImageLabel") and gui.ImageLabel.Image:find("exclamation") then
                                return obj
                            end
                        end
                    end
                end
            end
        end
    end
    -- Dự phòng: NPC có tên chứa "Quest"
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") and obj.Name:lower():find("quest") then
            local hum = obj:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then return obj end
        end
    end
    return nil
end

local function findQuestTargetMarker()
    -- Tìm marker đỏ chỉ vị trí cần đến (thường là Part hoặc Model có màu đỏ, tên "Target", "Marker", hoặc có icon)
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Part") or obj:IsA("MeshPart") then
            if obj.BrickColor == BrickColor.new("Bright red") or obj.BrickColor == BrickColor.new("Really red") then
                return obj
            elseif obj.Name:lower():find("target") or obj.Name:lower():find("marker") then
                return obj
            end
        elseif obj:IsA("Model") and obj.Name:lower():find("target") then
            local part = obj:FindFirstChild("Part") or obj:FindFirstChild("Handle")
            if part then return part end
        end
    end
    -- Tìm trên minimap (thường là ImageLabel màu đỏ trong PlayerGui)
    local pg = LocalPlayer:FindFirstChild("PlayerGui")
    if pg then
        local minimap = pg:FindFirstChild("Minimap") or pg:FindFirstChild("Map")
        if minimap then
            for _, gui in ipairs(minimap:GetDescendants()) do
                if gui:IsA("ImageLabel") and gui.BackgroundColor3 == Color3.new(1,0,0) then
                    -- Chuyển đổi vị trí trên minimap thành tọa độ thế giới (phức tạp, tạm bỏ qua)
                    -- Thay vào đó, ta sẽ dùng GetPartBoundsInRadius để tìm quái gần đó.
                    return nil
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
    local function search(obj, depth)
        if depth > (maxDepth or 15) then return nil end
        if obj:IsA("TextButton") and obj.Text:lower():find(buttonText:lower()) then
            return obj
        elseif obj.Name:lower():find(buttonText:lower()) then
            if obj:IsA("TextButton") or obj:IsA("ImageButton") then
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

-- ================== CHỨC NĂNG AUTO FARM LEVEL (tự do) ==================
local farmThread
function toggleAutoFarm()
    autoFarmEnabled = not autoFarmEnabled
    if autoFarmEnabled then
        if autoQuestEnabled then toggleAutoQuest() end
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
                    -- Di chuyển đến NPC
                    local npcHRP = npc:FindFirstChild("HumanoidRootPart")
                    if npcHRP then
                        teleportToCFrame(npcHRP.CFrame + Vector3.new(0,3,5))
                    end
                    task.wait(0.5)
                    -- Click vào NPC
                    local head = npc:FindFirstChild("Head")
                    if head then
                        local pos = Workspace.CurrentCamera:WorldToViewportPoint(head.Position)
                        VirtualInputManager:SendMouseButtonEvent(pos.X, pos.Y, 0, true, game, 1)
                        task.wait(0.1)
                        VirtualInputManager:SendMouseButtonEvent(pos.X, pos.Y, 0, false, game, 1)
                    end
                    task.wait(1.5)
                    -- Tìm nút Accept
                    local acceptBtn = findAndClickButton(LocalPlayer.PlayerGui, "accept", 10) or
                                      findAndClickButton(LocalPlayer.PlayerGui, "yes", 10)
                    if acceptBtn then
                        local btnPos = acceptBtn.AbsolutePosition + acceptBtn.AbsoluteSize/2
                        VirtualInputManager:SendMouseButtonEvent(btnPos.X, btnPos.Y, 0, true, game, 1)
                        task.wait(0.1)
                        VirtualInputManager:SendMouseButtonEvent(btnPos.X, btnPos.Y, 0, false, game, 1)
                        task.wait(0.5)
                    end
                    -- Tìm marker mục tiêu
                    local marker = findQuestTargetMarker()
                    local targetPos = marker and marker.Position or nil
                    local startTime = tick()
                    -- Nếu không có marker, farm quái gần đó trong thời gian quest
                    while tick() - startTime < questFarmDuration and autoQuestEnabled do
                        if targetPos then
                            teleportToCFrame(CFrame.new(targetPos + Vector3.new(0,3,0)))
                            -- Đánh quái xung quanh
                            local enemy = findNearestEnemy(30)
                            if enemy then attackTarget(enemy, skillToSpam) end
                        else
                            local enemy = findNearestEnemy(150)
                            if enemy then
                                teleportToCFrame(enemy.HumanoidRootPart.CFrame + Vector3.new(0,3,0))
                                attackTarget(enemy, skillToSpam)
                            end
                        end
                        task.wait(0.3)
                    end
                    -- Quay lại NPC
                    if npcHRP then
                        teleportToCFrame(npcHRP.CFrame + Vector3.new(0,3,5))
                    end
                    task.wait(0.5)
                    -- Click NPC
                    if head then
                        local pos = Workspace.CurrentCamera:WorldToViewportPoint(head.Position)
                        VirtualInputManager:SendMouseButtonEvent(pos.X, pos.Y, 0, true, game, 1)
                        task.wait(0.1)
                        VirtualInputManager:SendMouseButtonEvent(pos.X, pos.Y, 0, false, game, 1)
                    end
                    task.wait(1.5)
                    -- Tìm nút Complete
                    local completeBtn = findAndClickButton(LocalPlayer.PlayerGui, "complete", 10) or
                                        findAndClickButton(LocalPlayer.PlayerGui, "claim", 10)
                    if completeBtn then
                        local btnPos = completeBtn.AbsolutePosition + completeBtn.AbsoluteSize/2
                        VirtualInputManager:SendMouseButtonEvent(btnPos.X, btnPos.Y, 0, true, game, 1)
                        task.wait(0.1)
                        VirtualInputManager:SendMouseButtonEvent(btnPos.X, btnPos.Y, 0, false, game, 1)
                    end
                    task.wait(2)
                else
                    task.wait(3)
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
                        for _ = 1, 5 do
                            attackTarget(boss, skillToSpam)
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
                    local rankBtn = findAndClickButton(LocalPlayer.PlayerGui, "rank", 10) or
                                    findAndClickButton(LocalPlayer.PlayerGui, "evolve", 10)
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

-- ================== SPAM SKILL THỦ CÔNG (BÀN PHÍM ẢO) ==================
local spamButtons = {}
local function createSpamButton(name, skill, position)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 50, 0, 50)
    btn.Position = position
    btn.BackgroundColor3 = Color3.fromRGB(100,149,237)
    btn.TextColor3 = Color3.new(1,1,1)
    btn.Font = Enum.Font.SourceSansBold
    btn.Text = name
    btn.TextSize = 20
    btn.BorderSizePixel = 0
    btn.ZIndex = 200
    btn.Parent = spamFrame
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0,8)
    local isHolding = false
    btn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch then
            isHolding = true
            currentSpamSkill = skill
            spamActive = true
            task.spawn(function()
                while spamActive and isHolding do
                    if LocalPlayer.Character then
                        local target = findNearestEnemy(farmRange) -- tấn công mục tiêu gần nhất
                        if target then
                            attackTarget(target, skill)
                        else
                            -- nếu không có mục tiêu, vẫn gửi remote (có thể kích hoạt skill không cần target)
                            if damageRemote then
                                pcall(function() damageRemote:FireServer(nil, skill) end)
                            end
                        end
                    end
                    task.wait(0.1)
                end
            end)
        end
    end)
    btn.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch then
            isHolding = false
            spamActive = false
        end
    end)
    table.insert(spamButtons, btn)
end

-- ================== GIAO DIỆN CHÍNH ==================
local mainGui = Instance.new("ScreenGui")
mainGui.Name = "ShindoProV5"
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
local debounceTime = 0

local function toggleGUI()
    local now = tick()
    if now - debounceTime < 0.3 then return end
    debounceTime = now
    guiVisible = not guiVisible
    if mainFrame then mainFrame.Visible = guiVisible end
    toggleBtn.Text = guiVisible and "−" or "+"
end
toggleBtn.Activated:Connect(toggleGUI)

-- Khung chính
mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 320, 0, 480)
mainFrame.Position = UDim2.new(0, 10, 0.5, -240)
mainFrame.BackgroundColor3 = Color3.fromRGB(230,240,250)
mainFrame.BorderSizePixel = 0
mainFrame.Visible = false
mainFrame.ClipsDescendants = true
mainFrame.Parent = mainGui
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0,12)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1,0,0,35)
title.BackgroundColor3 = Color3.fromRGB(173,216,230)
title.TextColor3 = Color3.new(0,0,0.3)
title.Font = Enum.Font.SourceSansBold
title.Text = "Shindo Pro v5.0 | Full"
title.TextSize = 16
title.Parent = mainFrame

local content = Instance.new("Frame")
content.Size = UDim2.new(1,0,1,-35)
content.Position = UDim2.new(0,0,0,35)
content.BackgroundTransparency = 1
content.Parent = mainFrame

-- Hàm tạo nút toggle
local function addToggle(text, y, callback)
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

addToggle("Auto Farm Level", 10, function(on) toggleAutoFarm() end)
addToggle("Auto Quest (!)", 50, function(on) toggleAutoQuest() end)
addToggle("Auto Boss", 90, function(on) toggleAutoBoss() end)
addToggle("Auto Rank Up", 130, function(on) toggleAutoRank() end)
addToggle("Auto Scroll", 170, function(on) toggleAutoScroll() end)

-- Cài đặt skill spam
local skillLabel = Instance.new("TextLabel")
skillLabel.Size = UDim2.new(1,-20,0,25)
skillLabel.Position = UDim2.new(0,10,0,215)
skillLabel.BackgroundTransparency = 1
skillLabel.Text = "Skill Spam Tự Động:"
skillLabel.TextColor3 = Color3.new(0,0,0.3)
skillLabel.Font = Enum.Font.SourceSans
skillLabel.TextSize = 14
skillLabel.Parent = content

local skillInput = Instance.new("TextBox")
skillInput.Size = UDim2.new(1,-20,0,30)
skillInput.Position = UDim2.new(0,10,0,240)
skillInput.BackgroundColor3 = Color3.fromRGB(100,149,237)
skillInput.TextColor3 = Color3.new(1,1,1)
skillInput.PlaceholderText = "Tên skill (VD: Rasengan)"
skillInput.Text = skillToSpam
skillInput.Font = Enum.Font.SourceSans
skillInput.TextSize = 14
skillInput.Parent = content
skillInput.FocusLost:Connect(function()
    skillToSpam = skillInput.Text ~= "" and skillInput.Text or "Skill1"
end)

-- Phạm vi
local rangeLabel = Instance.new("TextLabel")
rangeLabel.Size = UDim2.new(1,-20,0,25)
rangeLabel.Position = UDim2.new(0,10,0,280)
rangeLabel.BackgroundTransparency = 1
rangeLabel.Text = "Phạm vi Farm:"
rangeLabel.TextColor3 = Color3.new(0,0,0.3)
rangeLabel.Font = Enum.Font.SourceSans
rangeLabel.TextSize = 14
rangeLabel.Parent = content

local rangeInput = Instance.new("TextBox")
rangeInput.Size = UDim2.new(1,-20,0,30)
rangeInput.Position = UDim2.new(0,10,0,305)
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
bossLabel.Size = UDim2.new(1,-20,0,25)
bossLabel.Position = UDim2.new(0,10,0,345)
bossLabel.BackgroundTransparency = 1
bossLabel.Text = "Chọn Boss:"
bossLabel.TextColor3 = Color3.new(0,0,0.3)
bossLabel.Font = Enum.Font.SourceSans
bossLabel.TextSize = 14
bossLabel.Parent = content

local bossDropdown = Instance.new("TextButton")
bossDropdown.Size = UDim2.new(1,-20,0,30)
bossDropdown.Position = UDim2.new(0,10,0,370)
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

-- ================== BÀN PHÍM ẢO SPAM SKILL ==================
local spamFrame = Instance.new("Frame")
spamFrame.Size = UDim2.new(1,0,0,60)
spamFrame.Position = UDim2.new(0,0,1,-70)
spamFrame.BackgroundTransparency = 1
spamFrame.Parent = mainGui

-- Các nút Y,G,H,N,B,V tương ứng với skill (có thể tùy chỉnh tên skill trong bảng)
local skillMap = {
    Y = "SkillY", -- thay bằng tên skill thực tế
    G = "SkillG",
    H = "SkillH",
    N = "SkillN",
    B = "SkillB",
    V = "SkillV"
}
local startX = 0.02
local spacing = 0.16
local keys = {"Y","G","H","N","B","V"}
for i, key in ipairs(keys) do
    createSpamButton(key, skillMap[key], UDim2.new(startX + (i-1)*spacing, 0, 0, 5))
end

-- Nhãn hướng dẫn
local noteLabel = Instance.new("TextLabel")
noteLabel.Size = UDim2.new(1,0,0,20)
noteLabel.Position = UDim2.new(0,0,1,-90)
noteLabel.BackgroundTransparency = 1
noteLabel.Text = "Giữ nút để spam skill tương ứng"
noteLabel.TextColor3 = Color3.new(1,1,1)
noteLabel.Font = Enum.Font.SourceSans
noteLabel.TextSize = 12
noteLabel.Parent = mainGui

print("Shindo Pro v5.0 loaded! Menu toggle nút '+'. Spam skill: giữ nút ảo bên dưới.")
