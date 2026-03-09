-- // KEY SYSTEM CONFIG
local CorrectKey = "BlameRoblox" -- Change your key here on GitHub anytime
_G.PrisonKey = _G.PrisonKey or "" -- This looks for the key in the executor memory

if _G.PrisonKey ~= CorrectKey then
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "Prison Life",
        Text = "Invalid or Missing Key! Set _G.PrisonKey first.",
        Duration = 10
    })
    return -- This stops the script from loading the rest of the code
end

print("Key Verified! Loading Prison Life Script...")

-- [PASTE THE REST OF YOUR ENTIRE V138 SCRIPT BELOW THIS LINE]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()

-- // CONFIG
local Config = {
    RemingtonPos = CFrame.new(820.3, 97.5, 2229.4), 
    MP5Pos = CFrame.new(813.7, 97.5, 2229.4),
    CrimBase = CFrame.new(-943.46, 94.12, 2063.63),
    PrisonPos = CFrame.new(918.77, 108, 2381.91),
    UnderOffset = Vector3.new(0, -26, 0), 
    GlideSpeed = 1.6, 
    AutoGuns = false,
    ArrestDuration = 3, -- UPDATED TO 3 SECONDS
    CooldownTime = 10,
    GlobalCooldownActive = false,
    CurrentCD = 0,
    Arresting = false,
    DeleteModKey = Enum.KeyCode.X,
    DeleteClickKey = Enum.UserInputType.MouseButton3,
    AimlockEnabled = false,
    AimKey = Enum.KeyCode.E,
    AimMode = "PRESS", 
    MaxAimDistance = 400,
    CurrentTarget = nil,
    ESPEnabled = true,
}

-- // 1. CORE FUNCTIONS
local function IsAlive(char)
    local hum = char and char:FindFirstChild("Humanoid")
    return hum and hum.Health > 0
end

local function GetClosestEnemy()
    if Config.CurrentTarget then
        local char = Config.CurrentTarget.Parent
        if not char or not IsAlive(char) or (LocalPlayer.Character.HumanoidRootPart.Position - Config.CurrentTarget.Position).Magnitude > Config.MaxAimDistance then
            Config.CurrentTarget = nil
            Config.AimlockEnabled = false 
            return nil
        end
        return Config.CurrentTarget
    end
    local target, dist = nil, math.huge
    local mousePos = UserInputService:GetMouseLocation()
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("Head") and p.Team ~= LocalPlayer.Team then
            local head = p.Character.Head
            local charDist = (LocalPlayer.Character.HumanoidRootPart.Position - head.Position).Magnitude
            if charDist <= Config.MaxAimDistance and IsAlive(p.Character) then
                local pos, onScreen = Camera:WorldToViewportPoint(head.Position)
                if onScreen then
                    local mag = (Vector2.new(pos.X, pos.Y) - mousePos).Magnitude
                    if mag < dist then dist = mag target = head end
                end
            end
        end
    end
    Config.CurrentTarget = target
    return target
end

local function SafeGlide(targetCFrame)
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    local distance = (root.Position - targetCFrame.Position).Magnitude
    local steps = math.floor(distance / Config.GlideSpeed)
    for i = 1, steps do
        if char:FindFirstChild("HumanoidRootPart") then
            root.CFrame = root.CFrame:Lerp(targetCFrame, i/steps)
            RunService.Heartbeat:Wait()
        end
    end
    root.CFrame = targetCFrame
end

local function GrabGuns()
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root or not Config.AutoGuns then return end
    local oldPos = root.CFrame
    root.CFrame = oldPos + Config.UnderOffset
    task.wait(0.3)
    SafeGlide(Config.RemingtonPos + Config.UnderOffset)
    task.wait(0.1)
    root.CFrame = Config.RemingtonPos
    task.wait(0.6)
    root.CFrame = Config.RemingtonPos + Config.UnderOffset
    task.wait(0.2)
    SafeGlide(Config.MP5Pos + Config.UnderOffset)
    task.wait(0.1)
    root.CFrame = Config.MP5Pos
    task.wait(0.6)
    root.CFrame = Config.MP5Pos + Config.UnderOffset
    task.wait(0.2)
    SafeGlide(oldPos + Config.UnderOffset)
    task.wait(0.2)
    root.CFrame = oldPos
end

LocalPlayer.CharacterAdded:Connect(function()
    if Config.AutoGuns then task.wait(0.5) GrabGuns() end
end)

-- // 2. GUI SETUP
local ScreenGui = Instance.new("ScreenGui", game.CoreGui)
local Main = Instance.new("Frame", ScreenGui)
local OpenBtn = Instance.new("ImageButton", ScreenGui)

OpenBtn.Size, OpenBtn.Position = UDim2.new(0, 50, 0, 50), UDim2.new(0, 5, 0.5, -25)
OpenBtn.BackgroundColor3, OpenBtn.BackgroundTransparency = Color3.fromRGB(15, 15, 15), 0.3
OpenBtn.Image = "rbxthumb://type=Asset&id=155615604&w=150&h=150"
Instance.new("UICorner", OpenBtn).CornerRadius = UDim.new(1, 0)
Instance.new("UIStroke", OpenBtn).Color = Color3.fromRGB(0, 120, 255)

Main.Size, Main.Position = UDim2.new(0, 420, 0, 280), UDim2.new(0, 60, 0.4, 0)
Main.BackgroundColor3, Main.BackgroundTransparency = Color3.fromRGB(10, 10, 10), 0.5
Main.Visible, Main.Active, Main.Draggable = false, true, true
Instance.new("UICorner", Main)
Instance.new("UIStroke", Main).Color = Color3.fromRGB(0, 120, 255)

local Sidebar = Instance.new("Frame", Main)
Sidebar.Size, Sidebar.BackgroundColor3, Sidebar.BackgroundTransparency = UDim2.new(0, 100, 1, 0), Color3.fromRGB(5, 5, 5), 0.4
Instance.new("UICorner", Sidebar)

local Container = Instance.new("Frame", Main)
Container.Size, Container.Position, Container.BackgroundTransparency = UDim2.new(1, -120, 1, -20), UDim2.new(0, 110, 0, 10), 1

local Pages = {Guns = Instance.new("Frame", Container), Arrest = Instance.new("Frame", Container), Teleport = Instance.new("Frame", Container), Misc = Instance.new("Frame", Container)}
for _, p in pairs(Pages) do p.Size, p.BackgroundTransparency, p.Visible = UDim2.new(1, 0, 1, 0), 1, false end
Pages.Guns.Visible = true

local function CreateBtn(txt, y, p, cb, color)
    local b = Instance.new("TextButton", p)
    b.Size, b.Position = UDim2.new(1, -10, 0, 35), UDim2.new(0, 5, 0, y)
    b.BackgroundColor3 = color or Color3.fromRGB(30, 30, 30)
    b.Text, b.TextColor3, b.Font, b.TextSize = txt, Color3.new(1, 1, 1), Enum.Font.GothamBold, 11
    Instance.new("UICorner", b)
    b.MouseButton1Click:Connect(function() cb(b) end)
    return b
end

CreateBtn("GUNS", 10, Sidebar, function() for _,p in pairs(Pages) do p.Visible = false end Pages.Guns.Visible = true end)
CreateBtn("ARREST", 50, Sidebar, function() for _,p in pairs(Pages) do p.Visible = false end Pages.Arrest.Visible = true end)
CreateBtn("TELEPORT", 90, Sidebar, function() for _,p in pairs(Pages) do p.Visible = false end Pages.Teleport.Visible = true end)
CreateBtn("MISC", 130, Sidebar, function() for _,p in pairs(Pages) do p.Visible = false end Pages.Misc.Visible = true end)

CreateBtn("AUTO GUNS: OFF", 10, Pages.Guns, function(b)
    Config.AutoGuns = not Config.AutoGuns
    b.Text = "AUTO GUNS: " .. (Config.AutoGuns and "ON" or "OFF")
    b.BackgroundColor3 = Config.AutoGuns and Color3.fromRGB(0, 180, 0) or Color3.fromRGB(30, 30, 30)
    if Config.AutoGuns then task.spawn(GrabGuns) end
end)

CreateBtn("CRIM BASE", 10, Pages.Teleport, function() if LocalPlayer.Character then LocalPlayer.Character.HumanoidRootPart.CFrame = Config.CrimBase end end, Color3.fromRGB(40, 40, 40))
CreateBtn("PRISON", 55, Pages.Teleport, function() if LocalPlayer.Character then LocalPlayer.Character.HumanoidRootPart.CFrame = Config.PrisonPos end end, Color3.fromRGB(40, 40, 40))

-- MISC PAGE
local function MakeUniversalBind(p, cfg, def, x)
    local b = CreateBtn(def, 0, p, function(btn)
        btn.Text = "..."
        local c; c = UserInputService.InputBegan:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.Keyboard or i.UserInputType.Name:find("MouseButton") then
                Config[cfg] = (i.UserInputType == Enum.UserInputType.Keyboard and i.KeyCode or i.UserInputType)
                btn.Text = (i.UserInputType == Enum.UserInputType.Keyboard and i.KeyCode.Name or i.UserInputType.Name:gsub("MouseButton", "M"))
                c:Disconnect()
            end
        end)
    end, Color3.fromRGB(40,40,40))
    b.Size, b.Position, b.TextColor3 = UDim2.new(0, 50, 0.6, 0), UDim2.new(0, x, 0.2, 0), Color3.fromRGB(0, 255, 255)
end

local AimBar = Instance.new("Frame", Pages.Misc)
AimBar.Size, AimBar.Position, AimBar.BackgroundColor3, AimBar.BackgroundTransparency = UDim2.new(1, -10, 0, 40), UDim2.new(0, 5, 0, 10), Color3.fromRGB(20, 20, 20), 0.3
Instance.new("UICorner", AimBar); Instance.new("UIStroke", AimBar).Color = Color3.fromRGB(0, 255, 255)
MakeUniversalBind(AimBar, "AimKey", "E", 5)
local ModeBtn = CreateBtn("Press To Aimlock", 0, AimBar, function(b)
    Config.AimMode = (Config.AimMode == "PRESS" and "HOLD" or "PRESS")
    b.Text = Config.AimMode:sub(1,1)..Config.AimMode:sub(2):lower() .. " To Aimlock"
end, Color3.fromRGB(40,40,40))
ModeBtn.Size, ModeBtn.Position, ModeBtn.TextColor3 = UDim2.new(1, -65, 0.6, 0), UDim2.new(0, 60, 0.2, 0), Color3.fromRGB(0, 255, 255)

local DelBar = Instance.new("Frame", Pages.Misc)
DelBar.Size, DelBar.Position, DelBar.BackgroundColor3, DelBar.BackgroundTransparency = UDim2.new(1, -10, 0, 40), UDim2.new(0, 5, 0, 55), Color3.fromRGB(20, 20, 20), 0.3
Instance.new("UICorner", DelBar); Instance.new("UIStroke", DelBar).Color = Color3.fromRGB(255, 0, 0)
MakeUniversalBind(DelBar, "DeleteModKey", "X", 5)
MakeUniversalBind(DelBar, "DeleteClickKey", "M3", 60)
local DelTxt = Instance.new("TextLabel", DelBar)
DelTxt.Size, DelTxt.Position, DelTxt.BackgroundTransparency, DelTxt.Text, DelTxt.TextColor3 = UDim2.new(1, -120, 1, 0), UDim2.new(0, 115, 0, 0), 1, "Delete Wall/Obj", Color3.new(1,1,1)
DelTxt.Font, DelTxt.TextSize = Enum.Font.GothamBold, 11

CreateBtn("ESP: ON", 100, Pages.Misc, function(b)
    Config.ESPEnabled = not Config.ESPEnabled
    b.Text = "ESP: " .. (Config.ESPEnabled and "ON" or "OFF")
    b.BackgroundColor3 = Config.ESPEnabled and Color3.fromRGB(0, 180, 0) or Color3.fromRGB(180, 0, 0)
end)

-- ARREST PAGE (GLOBAL COUNTDOWN)
local Scroll = Instance.new("ScrollingFrame", Pages.Arrest)
Scroll.Size, Scroll.BackgroundTransparency, Scroll.BorderSizePixel = UDim2.new(1, 0, 1, 0), 1, 0
Instance.new("UIListLayout", Scroll).Padding = UDim.new(0, 5)

local function UpdateArrest()
    for _, c in pairs(Scroll:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and (p.TeamColor.Name == "Really red" or (p.Team and p.Team.Name == "Criminals")) then
            local row = CreateBtn("   " .. p.DisplayName, 0, Scroll, function() end)
            row.TextXAlignment = Enum.TextXAlignment.Left
            local act = CreateBtn("ARREST", 0, row, function(b)
                if Config.Arresting or Config.GlobalCooldownActive or not p.Character or not p.Character:FindFirstChild("HumanoidRootPart") then return end
                
                Config.Arresting = true
                local old = LocalPlayer.Character.HumanoidRootPart.CFrame
                local start = tick()
                while tick() - start < Config.ArrestDuration do
                    if p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                        LocalPlayer.Character.HumanoidRootPart.CFrame = p.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, 1.2)
                    end
                    task.wait()
                end
                LocalPlayer.Character.HumanoidRootPart.CFrame = old
                Config.Arresting = false

                -- Start Global Countdown
                Config.GlobalCooldownActive = true
                task.spawn(function()
                    for i = Config.CooldownTime, 1, -1 do
                        Config.CurrentCD = i
                        task.wait(1)
                    end
                    Config.GlobalCooldownActive = false
                end)
            end, Color3.fromRGB(0, 120, 255))
            
            if Config.GlobalCooldownActive then
                act.Text = Config.CurrentCD .. "s"
                act.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
            end
            act.Size, act.Position = UDim2.new(0, 70, 0.7, 0), UDim2.new(1, -75, 0.15, 0)
        end
    end
end
task.spawn(function() while task.wait(0.5) do if Pages.Arrest.Visible then UpdateArrest() end end end)

-- // 3. LOOPS & INPUT
RunService.RenderStepped:Connect(function()
    if Config.AimlockEnabled then
        local t = GetClosestEnemy()
        if t then Camera.CFrame = CFrame.new(Camera.CFrame.Position, t.Position) end
    end
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            local hl = p.Character:FindFirstChild("NexusESP") or Instance.new("Highlight", p.Character)
            hl.Name = "NexusESP"
            hl.Enabled = (Config.ESPEnabled and p.Team ~= LocalPlayer.Team)
            hl.FillColor = p.TeamColor.Color
            hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        end
    end
end)

UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    local isAimInput = (input.KeyCode == Config.AimKey or input.UserInputType == Config.AimKey)
    if isAimInput then
        if Config.AimMode == "PRESS" then 
            Config.AimlockEnabled = not Config.AimlockEnabled 
            if not Config.AimlockEnabled then Config.CurrentTarget = nil end
        else Config.AimlockEnabled = true end
    end
    if input.UserInputType == Config.DeleteClickKey and (UserInputService:IsKeyDown(Config.DeleteModKey) or UserInputService:IsMouseButtonPressed(Config.DeleteModKey)) then
        local obj = Mouse.Target
        if obj then obj:Destroy() end
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if Config.AimMode == "HOLD" and (input.KeyCode == Config.AimKey or input.UserInputType == Config.AimKey) then
        Config.AimlockEnabled = false
        Config.CurrentTarget = nil
    end
end)

OpenBtn.MouseButton1Click:Connect(function() Main.Visible = not Main.Visible end)
