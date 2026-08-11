--[[
    SHINDO LIFE PRO MOBILE v7.0 – AUTO FARM, AUTO QUEST, AUTO RANK, AUTO SCROLL, SPAM SKILL, AUTO CHAKRA
    - Script dài, đầy đủ, ổn định tối đa trên Delta X.
    - Auto Farm: Tìm quái gần nhất, teleport, spam skill.
    - Auto Quest: Nhận quest (click Accept), tìm mục tiêu (marker đỏ / quái xung quanh), farm, nộp quest.
    - Auto Rank: Tự động rank khi có thể.
    - Auto Scroll: Nhặt scroll/paper.
    - Spam Skill: Nhập tên skill, toggle spam tự động.
    - Bàn phím ảo: Y,G,H,N,B,V (giữ để spam skill tương ứng, cấu hình được).
    - Auto Chakra: Hồi chakra tự động.
    - Menu cuộn được, nút toggle ổn định (Activated), giao diện xanh biển nhạt.
]]

-- ================== DỊCH VỤ ==================
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInputManager = game:GetService("VirtualInputManager")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

-- ================== TÌM REMOTE (ĐA LỚP) ==================
local function findRemote(name)
    -- Tìm trong ReplicatedStorage trước
    for _, v in ipairs(ReplicatedStorage:GetDescendants()) do
        if v:IsA("RemoteEvent") and v.Name == name then
            return v
        end
    end
    -- Tìm trong ReplicatedStorage.Remotes
    local remotesFolder = ReplicatedStorage:FindFirstChild("Remotes")
    if remotesFolder then
        for _, v in ipairs(remotesFolder:GetDescendants()) do
            if v:IsA("RemoteEvent") and v.Name == name then
                return v
            end
        end
    end
    -- Tìm trong Workspace (hiếm)
    for _, v in ipairs(Workspace:GetDescendants()) do
        if v:IsA("RemoteEvent") and v.Name == name then
            return v
        end
    end
    return nil
end

local damageRemote = findRemote("Damage") or findRemote("CastSpell") or findRemote("Attack")
local rankUpRemote = findRemote("RankUp") or findRemote("Promote") or findRemote("Evolve")
local chakraRemote = findRemote("ChargeChakra") or findRemote("RechargeChakra") or findRemote("RestoreChakra")
local questAcceptRemote = findRemote("AcceptQuest") or findRemote("StartQuest")
local questCompleteRemote = findRemote("CompleteQuest") or findRemote("FinishQuest")

-- ================== BIẾN TOÀN CỤC ==================
local autoFarmEnabled = false
local autoQuestEnabled = false
local autoRankEnabled = false
local autoScrollEnabled = false
local autoSpamEnabled = false
local autoChakraEnabled = false
local farmRange = 200
local spamSkillName = "Skill1"
local questFarmTime = 12 -- giây cho mỗi nhiệm vụ

-- Bàn phím ảo skill mặc định
local keySkills = {
    Y = "SkillY",
    G = "SkillG",
    H = "SkillH",
    N = "SkillN",
    B = "SkillB",
    V = "SkillV"
}

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

local function findQuestNPC()
    -- Tìm NPC có dấu "!" (quest chính), loại trừ dấu sao (*) hoặc nhiệm vụ phụ
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") then
            local hum = obj:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then
                local head = obj:FindFirstChild("Head")
                if head then
                    for _, gui in ipairs(head:GetChildren()) do
                        if gui:IsA("BillboardGui") then
                            local textLabel = gui:FindFirstChild("TextLabel")
                            local imageLabel = gui:FindFirstChild("ImageLabel")
                            if textLabel and textLabel.Text == "!" then
                                return obj
                            end
                            if imageLabel and imageLabel.Image:find("exclamation") then
                                return obj
                            end
                            -- Loại dấu sao
                            if textLabel and textLabel.Text == "*" then
                                return nil
                            end
                            if imageLabel and imageLabel.Image:find("star") then
                                return nil
                            end
                        end
                    end
                end
                -- Dự phòng nếu tên chứa "quest"
                if obj.Name:lower():find("quest") then
                    -- Không có dấu sao
                    return obj
                end
            end
        end
    end
    return nil
end

local function findQuestTargetMarker()
    -- Tìm Part/MeshPart màu đỏ tươi (marker mục tiêu)
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Part") or obj:IsA("MeshPart") then
            if obj.BrickColor == BrickColor.new("Bright red") or obj.BrickColor == BrickColor.new("Really red") then
                return obj
            end
        elseif obj:IsA("Model") then
            local part = obj:FindFirstChild("Part") or obj:FindFirstChild("Handle")
            if part and (part.BrickColor == BrickColor.new("Bright red") or part.BrickColor == BrickColor.new("Really red")) then
                return part
            end
        end
    end
    -- Tìm trên minimap (PlayerGui)
    local pg = LocalPlayer:FindFirstChild("PlayerGui")
    if pg then
        local minimap = pg:FindFirstChild("Minimap") or pg:FindFirstChild("Map")
        if minimap then
            for _, gui in ipairs(minimap:GetDescendants()) do
                if gui:IsA("ImageLabel") and gui.BackgroundColor3 == Color3.new(1,0,0) then
                    -- Không thể chuyển chính xác, ta sẽ dùng cách khác: tìm quái gần NPC
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

local function fireSkill(target, skillName)
    skillName = skillName or spamSkillName
    if damageRemote then
        pcall(function()
            damageRemote:FireServer(target, skillName)
        end)
    else
        local root = target and target:FindFirstChild("HumanoidRootPart")
        if root then
            local pos, onScreen = Workspace.CurrentCamera:WorldToViewportPoint(root.Position)
            if onScreen then
                VirtualInputManager:SendMouseButtonEvent(pos.X, pos.Y, 0, true, game, 1)
                task.wait(0.05)
                VirtualInputManager:SendMouseButtonEvent(pos.X, pos.Y, 0, false, game, 1)
            end
        else
            -- click giữa màn hình
            VirtualInputManager:SendMouseButtonEvent(200, 200, 0, true, game, 1)
            task.wait(0.05)
            VirtualInputManager:SendMouseButtonEvent(200, 200, 0, false, game, 1)
        end
    end
end

local function chargeChakra()
    if chakraRemote then
        pcall(function() chakraRemote:FireServer() end)
    else
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.C, false, game)
        task.wait(0.1)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.C, false, game)
    end
end

local function clickButton(guiObj)
    if guiObj then
        local pos = guiObj.AbsolutePosition + guiObj.AbsoluteSize/2
        VirtualInputManager:SendMouseButtonEvent(pos.X, pos.Y, 0, true, game, 1)
        task.wait(0.1)
        VirtualInputManager:SendMouseButtonEvent(pos.X, pos.Y, 0, false, game, 1)
    end
end

local function findAndClickButton(parent, textContains)
    local function search(obj, depth)
        if depth > 15 then return nil end
        if obj:IsA("TextButton") and obj.Text:lower():find(textContains:lower()) then
            return obj
        elseif obj.Name:lower():find(textContains:lower()) then
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
    return search(parent, 0)
end

-- ================== AUTO FARM LEVEL ==================
local farmThread
function toggleAutoFarm()
    autoFarmEnabled = not autoFarmEnabled
    if autoFarmEnabled then
        if autoQuestEnabled then toggleAutoQuest() end -- tắt quest
        farmThread = task.spawn(function()
            while autoFarmEnabled do
                local target = findNearestEnemy(farmRange)
                if target then
                    teleportToCFrame(target.HumanoidRootPart.CFrame + Vector3.new(0,3,0))
                    fireSkill(target, spamSkillName)
                end
                task.wait(0.2)
            end
        end)
    else
        if farmThread then task.cancel(farmThread) end
    end
end

-- ================== AUTO QUEST ==================
local questThread
function toggleAutoQuest()
    autoQuestEnabled = not autoQuestEnabled
    if autoQuestEnabled then
        if autoFarmEnabled then toggleAutoFarm() end -- tắt farm tự do
        questThread = task.spawn(function()
            while autoQuestEnabled do
                local npc = findQuestNPC()
                if not npc then
                    task.wait(3)
                    continue
                end
                -- Di chuyển đến NPC
                local npcHRP = npc:FindFirstChild("HumanoidRootPart")
                if npcHRP then
                    teleportToCFrame(npcHRP.CFrame + Vector3.new(0,3,5))
                end
                task.wait(0.5)
                -- Click vào NPC để mở hội thoại
                local head = npc:FindFirstChild("Head")
                if head then
                    local pos = Workspace.CurrentCamera:WorldToViewportPoint(head.Position)
                    VirtualInputManager:SendMouseButtonEvent(pos.X, pos.Y, 0, true, game, 1)
                    task.wait(0.1)
                    VirtualInputManager:SendMouseButtonEvent(pos.X, pos.Y, 0, false, game, 1)
                end
                task.wait(1)
                -- Tìm nút Accept và click
                local acceptBtn = findAndClickButton(LocalPlayer.PlayerGui, "accept") or
                                  findAndClickButton(LocalPlayer.PlayerGui, "yes")
                if acceptBtn then
                    clickButton(acceptBtn)
                    task.wait(1)
                end
                -- Tìm marker mục tiêu (chấm đỏ)
                local marker = findQuestTargetMarker()
                local targetPosition = marker and marker.Position or nil
                local startTime = tick()
                -- Farm trong thời gian quy định, ưu tiên marker nếu có
                while tick() - startTime < questFarmTime and autoQuestEnabled do
                    if targetPosition then
                        teleportToCFrame(CFrame.new(targetPosition + Vector3.new(0,3,0)))
                        -- Đánh quái trong phạm vi hẹp
                        local enemy = findNearestEnemy(50)
                        if enemy then
                            fireSkill(enemy, spamSkillName)
                        end
                    else
                        -- Không có marker, farm quái gần NPC
                        local enemy = findNearestEnemy(150)
                        if enemy then
                            teleportToCFrame(enemy.HumanoidRootPart.CFrame + Vector3.new(0,3,0))
                            fireSkill(enemy, spamSkillName)
                        end
                    end
                    task.wait(0.3)
                end
                -- Quay lại NPC
                if npcHRP then
                    teleportToCFrame(npcHRP.CFrame + Vector3.new(0,3,5))
                end
                task.wait(0.5)
                -- Click NPC để hoàn thành
                if head then
                    local pos = Workspace.CurrentCamera:WorldToViewportPoint(head.Position)
                    VirtualInputManager:SendMouseButtonEvent(pos.X, pos.Y, 0, true, game, 1)
                    task.wait(0.1)
                    VirtualInputManager:SendMouseButtonEvent(pos.X, pos.Y, 0, false, game, 1)
                end
                task.wait(1)
                -- Tìm nút Complete/Claim
                local completeBtn = findAndClickButton(LocalPlayer.PlayerGui, "complete") or
                                    findAndClickButton(LocalPlayer.PlayerGui, "claim")
                if completeBtn then
                    clickButton(completeBtn)
                    task.wait(1)
                end
                task.wait(2) -- chờ nhận thưởng, loop tiếp
            end
        end)
    else
        if questThread then task.cancel(questThread) end
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
                    local rankBtn = findAndClickButton(LocalPlayer.PlayerGui, "rank") or
                                    findAndClickButton(LocalPlayer.PlayerGui, "evolve")
                    if rankBtn then
                        clickButton(rankBtn)
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
                        pcall(function()
                            firetouchinterest(LocalPlayer.Character.HumanoidRootPart, part, 0)
                        end)
                        task.wait(0.3)
                    end
                end
                task.wait(0.5)
            end
        end)
    else
        if scrollThread then task.cancel(scrollThread) end
    end
end

-- ================== AUTO SPAM SKILL ==================
local spamThread
function toggleAutoSpam()
    autoSpamEnabled = not autoSpamEnabled
    if autoSpamEnabled then
        spamThread = task.spawn(function()
            while autoSpamEnabled do
                local target = findNearestEnemy(farmRange) or nil
                fireSkill(target, spamSkillName)
                task.wait(0.1)
            end
        end)
    else
        if spamThread then task.cancel(spamThread) end
    end
end

-- ================== AUTO CHAKRA ==================
local chakraThread
function toggleAutoChakra()
    autoChakraEnabled = not autoChakraEnabled
    if autoChakraEnabled then
        chakraThread = task.spawn(function()
            while autoChakraEnabled do
                chargeChakra()
                task.wait(3)
            end
        end)
    else
        if chakraThread then task.cancel(chakraThread) end
    end
end

-- ================== BÀN PHÍM ẢO SPAM SKILL ==================
local function createVirtualKey(name, defaultSkill, position)
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
    btn.Parent = keyFrame
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0,8)
    local skillName = defaultSkill
    local isHolding = false
    btn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch then
            isHolding = true
            task.spawn(function()
                while isHolding do
                    local target = findNearestEnemy(farmRange) or nil
                    fireSkill(target, skillName)
                    task.wait(0.1)
                end
            end)
        end
    end)
    btn.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch then
            isHolding = false
        end
    end)
    return {
        button = btn,
        setSkill = function(newSkill) skillName = newSkill end
    }
end

-- ================== GIAO DIỆN CHÍNH ==================
local mainGui = Instance.new("ScreenGui")
mainGui.Name = "ShindoProV7"
mainGui.ResetOnSpawn = false
mainGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

-- Nút toggle menu (xanh nhạt, Activated)
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
local debounce = 0

local function toggleGUI()
    if tick() - debounce < 0.3 then return end
    debounce = tick()
    guiVisible = not guiVisible
    if mainFrame then mainFrame.Visible = guiVisible end
    toggleBtn.Text = guiVisible and "−" or "+"
end
toggleBtn.Activated:Connect(toggleGUI)

-- Khung chính cuộn được
mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 300, 0, 450)
mainFrame.Position = UDim2.new(0, 10, 0.5, -225)
mainFrame.BackgroundColor3 = Color3.fromRGB(230,240,250)
mainFrame.BorderSizePixel = 0
mainFrame.Visible = false
mainFrame.Parent = mainGui
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0,12)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1,0,0,35)
title.BackgroundColor3 = Color3.fromRGB(173,216,230)
title.TextColor3 = Color3.new(0,0,0.3)
title.Font = Enum.Font.SourceSansBold
title.Text = "Shindo Pro v7.0"
title.TextSize = 16
title.Parent = mainFrame

local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Size = UDim2.new(1,0,1,-35)
scrollFrame.Position = UDim2.new(0,0,0,35)
scrollFrame.BackgroundTransparency = 1
scrollFrame.CanvasSize = UDim2.new(0,0,0,700)
scrollFrame.ScrollBarThickness = 8
scrollFrame.Parent = mainFrame

local content = Instance.new("Frame")
content.Size = UDim2.new(1,0,0,700)
content.BackgroundTransparency = 1
content.Parent = scrollFrame

-- Hàm tạo nút toggle
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
addToggleButton("Auto Quest", 50, function(on) toggleAutoQuest() end)
addToggleButton("Auto Rank Up", 90, function(on) toggleAutoRank() end)
addToggleButton("Auto Scroll", 130, function(on) toggleAutoScroll() end)
addToggleButton("Auto Spam Skill", 170, function(on) toggleAutoSpam() end)
addToggleButton("Auto Chakra", 210, function(on) toggleAutoChakra() end)

-- Cài đặt tên skill spam chính
local skillLabel = Instance.new("TextLabel")
skillLabel.Size = UDim2.new(1,-20,0,25)
skillLabel.Position = UDim2.new(0,10,0,255)
skillLabel.BackgroundTransparency = 1
skillLabel.Text = "Skill Spam Chính:"
skillLabel.TextColor3 = Color3.new(0,0,0.3)
skillLabel.Font = Enum.Font.SourceSans
skillLabel.TextSize = 14
skillLabel.Parent = content

local skillInput = Instance.new("TextBox")
skillInput.Size = UDim2.new(1,-20,0,30)
skillInput.Position = UDim2.new(0,10,0,280)
skillInput.BackgroundColor3 = Color3.fromRGB(100,149,237)
skillInput.TextColor3 = Color3.new(1,1,1)
skillInput.PlaceholderText = "Nhập tên skill..."
skillInput.Text = spamSkillName
skillInput.Font = Enum.Font.SourceSans
skillInput.TextSize = 14
skillInput.Parent = content
skillInput.FocusLost:Connect(function()
    spamSkillName = skillInput.Text ~= "" and skillInput.Text or "Skill1"
end)

-- Phạm vi Farm
local rangeLabel = Instance.new("TextLabel")
rangeLabel.Size = UDim2.new(1,-20,0,25)
rangeLabel.Position = UDim2.new(0,10,0,320)
rangeLabel.BackgroundTransparency = 1
rangeLabel.Text = "Phạm vi Farm:"
rangeLabel.TextColor3 = Color3.new(0,0,0.3)
rangeLabel.Font = Enum.Font.SourceSans
rangeLabel.TextSize = 14
rangeLabel.Parent = content

local rangeInput = Instance.new("TextBox")
rangeInput.Size = UDim2.new(1,-20,0,30)
rangeInput.Position = UDim2.new(0,10,0,345)
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

-- Bàn phím ảo (luôn hiển thị)
local keyFrame = Instance.new("Frame")
keyFrame.Size = UDim2.new(1,0,0,60)
keyFrame.Position = UDim2.new(0,0,1,-70)
keyFrame.BackgroundTransparency = 1
keyFrame.Parent = mainGui

local keys = {"Y","G","H","N","B","V"}
local keyButtons = {}
local startX = 0.02
local spacing = 0.16
for i, key in ipairs(keys) do
    local obj = createVirtualKey(key, keySkills[key], UDim2.new(startX + (i-1)*spacing, 0, 0, 5))
    keyButtons[key] = obj
end

-- Cấu hình skill bàn phím ảo
local keyCfgLabel = Instance.new("TextLabel")
keyCfgLabel.Size = UDim2.new(1,-20,0,25)
keyCfgLabel.Position = UDim2.new(0,10,0,385)
keyCfgLabel.BackgroundTransparency = 1
keyCfgLabel.Text = "Skill cho phím Y G H N B V:"
keyCfgLabel.TextColor3 = Color3.new(0,0,0.3)
keyCfgLabel.Font = Enum.Font.SourceSans
keyCfgLabel.TextSize = 12
keyCfgLabel.Parent = content

local keyCfgInputs = {}
local cfgY = 410
for i, key in ipairs(keys) do
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(0,20,0,25)
    lbl.Position = UDim2.new(0,10,0, cfgY + (i-1)*30)
    lbl.BackgroundTransparency = 1
    lbl.Text = key
    lbl.TextColor3 = Color3.new(0,0,0.3)
    lbl.Font = Enum.Font.SourceSansBold
    lbl.TextSize = 14
    lbl.Parent = content

    local inp = Instance.new("TextBox")
    inp.Size = UDim2.new(1,-35,0,25)
    inp.Position = UDim2.new(0,35,0, cfgY + (i-1)*30)
    inp.BackgroundColor3 = Color3.fromRGB(100,149,237)
    inp.TextColor3 = Color3.new(1,1,1)
    inp.Text = keySkills[key]
    inp.Font = Enum.Font.SourceSans
    inp.TextSize = 14
    inp.Parent = content
    inp.FocusLost:Connect(function()
        local newSkill = inp.Text ~= "" and inp.Text or keySkills[key]
        keySkills[key] = newSkill
        if keyButtons[key] then keyButtons[key].setSkill(newSkill) end
    end)
    keyCfgInputs[key] = inp
end

scrollFrame.CanvasSize = UDim2.new(0,0,0,cfgY + #keys*30 + 30)

print("Shindo Pro v7.0 loaded! Menu: nút '+' xanh. Kéo xuống để thấy hết.")
