-- Shindo Life Pro Mobile v2.0 – palofsc
-- Dành cho Delta X, loadstring: loadstring(game:HttpGet("RAW_URL_HERE"))()
local Players=game:GetService("Players")local LocalPlayer=Players.LocalPlayer
local Workspace=game:GetService("Workspace")local UserInputService=game:GetService("UserInputService")
local RunService=game:GetService("RunService")local TweenService=game:GetService("TweenService")
local ReplicatedStorage=game:GetService("ReplicatedStorage")local CoreGui=game:GetService("CoreGui")
local function getRemote(name)for _,v in pairs(ReplicatedStorage:GetDescendants())do if v:IsA("RemoteEvent")and v.Name==name then return v end end end
local damageRemote=getRemote("Damage")or getRemote("CastSpell")or getRemote("Attack")
local function findEnemy(r)local c=LocalPlayer.Character if not c then return nil end local hrp=c:FindFirstChild("HumanoidRootPart")if not hrp then return nil end local nearest,dist=nil,r or 150 for _,o in pairs(Workspace:GetDescendants())do if o:IsA("Model")and o~=c then local hum=o:FindFirstChildOfClass("Humanoid")if hum and hum.Health>0 then local root=o:FindFirstChild("HumanoidRootPart")if root then local d=(hrp.Position-root.Position).Magnitude if d<dist then dist=d nearest=o end end end end end return nearest end
local function teleport(cf)local c=LocalPlayer.Character if c and c:FindFirstChild("HumanoidRootPart")then c.HumanoidRootPart.CFrame=cf end end
local flyEnabled=false local bodyVel,bodyGyro local flySpeed=50
local function toggleFly()flyEnabled=not flyEnabled local c=LocalPlayer.Character if not c then return end local hrp=c:FindFirstChild("HumanoidRootPart")if not hrp then return end if flyEnabled then bodyVel=Instance.new("BodyVelocity")bodyVel.MaxForce=Vector3.new(1,1,1)*math.huge bodyVel.Velocity=Vector3.new()bodyVel.Parent=hrp bodyGyro=Instance.new("BodyGyro")bodyGyro.MaxTorque=Vector3.new(1,1,1)*math.huge bodyGyro.CFrame=hrp.CFrame bodyGyro.Parent=hrp else if bodyVel then bodyVel:Destroy()end if bodyGyro then bodyGyro:Destroy()end end end
local noclipEnabled=false local function toggleNoclip()noclipEnabled=not noclipEnabled local c=LocalPlayer.Character if c then for _,p in pairs(c:GetDescendants())do if p:IsA("BasePart")then p.CanCollide=not noclipEnabled end end end end
local autoFarmEnabled=false local spamSkill=true local farmRange=150
local function toggleAutoFarm()autoFarmEnabled=not autoFarmEnabled if autoFarmEnabled then spawn(function()while autoFarmEnabled do local t=findEnemy(farmRange)if t and t:FindFirstChild("HumanoidRootPart")then teleport(t.HumanoidRootPart.CFrame+Vector3.new(0,3,0))if spamSkill and damageRemote then pcall(function()damageRemote:FireServer(t,"Skill1")end)end end wait(0.1)end end)end end
local autoBossEnabled=false local targetBoss="Tất cả"
local function findBoss()for _,o in pairs(Workspace:GetDescendants())do if o:IsA("Model")and o.Name:lower():find("boss")then local hum=o:FindFirstChildOfClass("Humanoid")if hum and hum.Health>0 then if targetBoss=="Tất cả"then return o elseif o.Name:lower():find(targetBoss:lower())then return o end end end end return nil end
local function toggleAutoBoss()autoBossEnabled=not autoBossEnabled if autoBossEnabled then spawn(function()while autoBossEnabled do local b=findBoss()if b and b:FindFirstChild("HumanoidRootPart")then teleport(b.HumanoidRootPart.CFrame+Vector3.new(0,5,0))if spamSkill and damageRemote then pcall(function()damageRemote:FireServer(b,"Ultimate")end)end end wait(0.2)end end)end end
local autoScrollEnabled=false
local function findScroll()for _,o in pairs(Workspace:GetDescendants())do if o:IsA("Model")and(o.Name:lower():find("scroll")or o.Name:lower():find("paper"))then return o end end end
local function toggleAutoScroll()autoScrollEnabled=not autoScrollEnabled if autoScrollEnabled then spawn(function()while autoScrollEnabled do local s=findScroll()if s and s:FindFirstChild("Part")then teleport(s.Part.CFrame)wait(0.5)end wait(0.5)end end)end end
-- GUI (thu gọn, nút toggle +)
local ScreenGui=Instance.new("ScreenGui")ScreenGui.Name="ShindoPro"ScreenGui.ResetOnSpawn=false ScreenGui.Parent=LocalPlayer:WaitForChild("PlayerGui")
local toggleBtn=Instance.new("TextButton")toggleBtn.Size=UDim2.new(0,50,0,50)toggleBtn.Position=UDim2.new(0,10,0.5,-25)
toggleBtn.BackgroundColor3=Color3.new(0.2,0.2,0.2)toggleBtn.BackgroundTransparency=0.5 toggleBtn.Text="+" toggleBtn.TextColor3=Color3.new(1,1,1)toggleBtn.TextSize=30 toggleBtn.Font=Enum.Font.SourceSansBold toggleBtn.ZIndex=10 toggleBtn.Parent=ScreenGui
local mainFrame=Instance.new("Frame")mainFrame.Size=UDim2.new(0,300,0,400)mainFrame.Position=UDim2.new(0,10,0.5,-200)mainFrame.BackgroundColor3=Color3.new(0.1,0.1,0.1)mainFrame.BorderSizePixel=0 mainFrame.Visible=false mainFrame.Parent=ScreenGui
Instance.new("UICorner",mainFrame).CornerRadius=UDim.new(0,12)
local title=Instance.new("TextLabel")title.Size=UDim2.new(1,0,0,30)title.BackgroundColor3=Color3.new(0.2,0.2,0.2)title.TextColor3=Color3.new(1,1,1)title.Font=Enum.Font.SourceSansBold title.Text="Shindo Pro v2.0"title.TextSize=16 title.Parent=mainFrame
Instance.new("UICorner",title).CornerRadius=UDim.new(0,8)
local tabContainer=Instance.new("Frame")tabContainer.Size=UDim2.new(1,0,1,-35)tabContainer.Position=UDim2.new(0,0,0,35)tabContainer.BackgroundTransparency=1 tabContainer.Parent=mainFrame
local tabs={}
local function addTabButton(name,pos)local b=Instance.new("TextButton")b.Size=UDim2.new(1/6,0,0,25)b.Position=UDim2.new((pos-1)/6,0,0,0)b.BackgroundColor3=Color3.new(0.3,0.3,0.3)b.TextColor3=Color3.new(1,1,1)b.Font=Enum.Font.SourceSans b.Text=name b.TextSize=14 b.Parent=title
b.MouseButton1Click:Connect(function()for _,t in pairs(tabs)do t.Visible=false end tabs[name].Visible=true end)return b end
local function addTab(name)local t=Instance.new("Frame")t.Size=UDim2.new(1,0,1,0)t.BackgroundTransparency=1 t.Visible=false t.Parent=tabContainer tabs[name]=t return t end
local tabMain=addTab("Main")local tabFarm=addTab("Farm")local tabBoss=addTab("Boss")local tabScroll=addTab("Scroll")local tabTele=addTab("Tele")local tabSet=addTab("Set")
addTabButton("Main",1)addTabButton("Farm",2)addTabButton("Boss",3)addTabButton("Scroll",4)addTabButton("Tele",5)addTabButton("Set",6)
tabs["Main"].Visible=true
-- Thêm nút chức năng vào tab Main
local function addButton(parent,text,y,action)local b=Instance.new("TextButton")b.Size=UDim2.new(1,-20,0,35)b.Position=UDim2.new(0,10,0,y)b.BackgroundColor3=Color3.new(0.4,0.4,0.4)b.TextColor3=Color3.new(1,1,1)b.Font=Enum.Font.SourceSans b.Text=text..": OFF"b.TextSize=14 b.Parent=parent Instance.new("UICorner",b).CornerRadius=UDim.new(0,6)local e=false b.MouseButton1Click:Connect(function()e=not e b.Text=text..": "..(e and "ON"or"OFF")b.BackgroundColor3=e and Color3.new(0.2,0.8,0.2)or Color3.new(0.4,0.4,0.4)action(e)end)end
addButton(tabMain,"Bay",10,toggleFly)
addButton(tabMain,"Xuyên Tường",50,toggleNoclip)
addButton(tabMain,"Auto Farm",90,toggleAutoFarm)
addButton(tabMain,"Auto Boss",130,toggleAutoBoss)
addButton(tabMain,"Auto Scroll",170,toggleAutoScroll)
-- Tab Farm: spam skill, phạm vi
local spamBtn=addButton(tabFarm,"Spam Skill",10,function(on)spamSkill=on end)spamBtn.Text="Spam Skill: ON"spamBtn.BackgroundColor3=Color3.new(0.2,0.8,0.2)
local rangeBox=Instance.new("TextBox")rangeBox.Size=UDim2.new(1,-20,0,30)rangeBox.Position=UDim2.new(0,10,0,50)rangeBox.BackgroundColor3=Color3.new(0.3,0.3,0.3)rangeBox.TextColor3=Color3.new(1,1,1)rangeBox.PlaceholderText="Phạm vi (mặc định 150)"rangeBox.Text="150"rangeBox.Parent=tabFarm
rangeBox.FocusLost:Connect(function()farmRange=tonumber(rangeBox.Text)or 150 end)
-- Tab Boss: danh sách chọn
local bossNames={"Tất cả","Akuma","Tengoku","Renshiki","Forge Boss"}
for i,name in ipairs(bossNames)do local btn=Instance.new("TextButton")btn.Size=UDim2.new(1,-20,0,30)btn.Position=UDim2.new(0,10,0,10+(i-1)*35)btn.BackgroundColor3=Color3.new(0.4,0.4,0.4)btn.TextColor3=Color3.new(1,1,1)btn.Text=name btn.Parent=tabBoss btn.MouseButton1Click:Connect(function()targetBoss=name end)end
-- Tab Scroll: làm mới + danh sách
local refreshBtn=Instance.new("TextButton")refreshBtn.Size=UDim2.new(1,-20,0,30)refreshBtn.Position=UDim2.new(0,10,0,10)refreshBtn.BackgroundColor3=Color3.new(0.4,0.4,0.4)refreshBtn.TextColor3=Color3.new(1,1,1)refreshBtn.Text="Làm mới scroll"refreshBtn.Parent=tabScroll
local scrollListFrame=Instance.new("ScrollingFrame")scrollListFrame.Size=UDim2.new(1,-20,1,-50)scrollListFrame.Position=UDim2.new(0,10,0,50)scrollListFrame.BackgroundColor3=Color3.new(0.2,0.2,0.2)scrollListFrame.CanvasSize=UDim2.new(0,0,0,0)scrollListFrame.Name="ScrollList"scrollListFrame.Parent=tabScroll
refreshBtn.MouseButton1Click:Connect(function()local scrolls={}for _,o in pairs(Workspace:GetDescendants())do if o:IsA("Model")and(o.Name:lower():find("scroll")or o.Name:lower():find("paper"))then table.insert(scrolls,o)end end
for _,v in ipairs(scrollListFrame:GetChildren())do if v:IsA("TextButton")then v:Destroy()end end
for i,s in ipairs(scrolls)do local b=Instance.new("TextButton")b.Size=UDim2.new(1,0,0,25)b.Position=UDim2.new(0,0,0,(i-1)*25)b.Text=s.Name b.BackgroundColor3=Color3.new(0.3,0.3,0.3)b.TextColor3=Color3.new(1,1,1)b.Parent=scrollListFrame
b.MouseButton1Click:Connect(function()if s:FindFirstChild("Part")then teleport(s.Part.CFrame)end end)end
scrollListFrame.CanvasSize=UDim2.new(0,0,0,#scrolls*25)end)
-- Tab Teleport
local teleportLocations={["Làng Lá"]=CFrame.new(-300,10,200),["Làng Cát"]=CFrame.new(800,10,-400),["Làng Sương Mù"]=CFrame.new(200,10,900),["Thác Nước"]=CFrame.new(0,50,-800),["Rừng Chết"]=CFrame.new(-700,10,-300)}
local teleFrame=Instance.new("ScrollingFrame")teleFrame.Size=UDim2.new(1,-20,1,-10)teleFrame.Position=UDim2.new(0,10,0,10)teleFrame.BackgroundColor3=Color3.new(0.2,0.2,0.2)teleFrame.CanvasSize=UDim2.new(0,0,0,0)teleFrame.Parent=tabTele
local idx=0
for name,cf in pairs(teleportLocations)do local b=Instance.new("TextButton")b.Size=UDim2.new(1,0,0,25)b.Position=UDim2.new(0,0,0,idx*25)b.Text=name b.BackgroundColor3=Color3.new(0.3,0.3,0.3)b.TextColor3=Color3.new(1,1,1)b.Parent=teleFrame
b.MouseButton1Click:Connect(function()teleport(cf)end)idx=idx+1 end
teleFrame.CanvasSize=UDim2.new(0,0,0,idx*25)
-- Tab Settings
local speedBox=Instance.new("TextBox")speedBox.Size=UDim2.new(1,-20,0,30)speedBox.Position=UDim2.new(0,10,0,10)speedBox.BackgroundColor3=Color3.new(0.3,0.3,0.3)speedBox.TextColor3=Color3.new(1,1,1)speedBox.PlaceholderText="Tốc độ bay (50)"speedBox.Text="50"speedBox.Parent=tabSet
speedBox.FocusLost:Connect(function()flySpeed=tonumber(speedBox.Text)or 50 if bodyVel then bodyVel.MaxForce=Vector3.new(1,1,1)*math.huge end end)
-- Toggle visibility
local guiVisible=false
toggleBtn.MouseButton1Click:Connect(function()guiVisible=not guiVisible mainFrame.Visible=guiVisible toggleBtn.Text=guiVisible and"-"or"+"end)
-- Joystick fly đơn giản (dùng nút bay ẩn, tap để lên/xuống – mobile chủ yếu dùng Auto Farm nên bay tùy chọn)
local joystickActive=false
local joystickFrame=Instance.new("Frame")joystickFrame.Size=UDim2.new(0,120,0,120)joystickFrame.Position=UDim2.new(0,30,0.8,0)joystickFrame.BackgroundColor3=Color3.new(0,0,0)joystickFrame.BackgroundTransparency=0.7 joystickFrame.BorderSizePixel=0 joystickFrame.Visible=false joystickFrame.Parent=ScreenGui
local joyBtn=Instance.new("ImageButton")joyBtn.Size=UDim2.new(0,50,0,50)joyBtn.Position=UDim2.new(0.5,-25,0.5,-25)joyBtn.BackgroundColor3=Color3.new(1,1,1)joyBtn.BackgroundTransparency=0.5 joyBtn.Image="rbxassetid://0"joyBtn.Parent=joystickFrame
joyBtn.InputBegan:Connect(function(i)if i.UserInputType==Enum.UserInputType.Touch then joystickActive=true end end)
joyBtn.InputChanged:Connect(function(i)if joystickActive and i.UserInputType==Enum.UserInputType.Touch then
local delta=i.Position-joyBtn.AbsolutePosition-joyBtn.AbsoluteSize/2
if bodyVel then bodyVel.Velocity=Vector3.new(delta.X,0,delta.Y)*flySpeed/50+Vector3.new(0,delta.Y>0 and flySpeed/2 or -flySpeed/2,0)end end end)
joyBtn.InputEnded:Connect(function()joystickActive=false if bodyVel then bodyVel.Velocity=Vector3.new()end end)
-- Bay toggle cập nhật hiển thị joystick
local oldToggleFly=toggleFly
toggleFly=function()oldToggleFly()joystickFrame.Visible=flyEnabled end
print("Shindo Life Pro ready! Loadstring URL: (copy raw)")
