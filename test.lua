-- // AIM ASSIST / SILENT AIM CLIENT-SIDE // --
-- // Compatible: Krnl, Fluxus, Codex, Hydrogen, Delta, Arceus X, Solara, Wave, Electron // --

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

-- // CONFIG // --
local Config = {
    Enabled = true,
    TeamCheck = true,
    WallCheck = true,
    AliveCheck = true,
    
    -- Aim Assist (Camera)
    AimAssist = true,
    AimKey = Enum.UserInputType.MouseButton2, -- Clic droit
    Smoothness = 0.12, -- 0.01 = instant, 0.3 = très fluide
    FOV = 120,
    ShowFOV = true,
    FOVColor = Color3.fromRGB(255, 50, 50),
    TargetPart = "Head", -- "Head", "HumanoidRootPart", "UpperTorso"
    TargetPriority = "Distance", -- "Distance", "Crosshair", "Health"
    
    -- Silent Aim (Client Visual Only - ton curseur ne bouge pas, mais les tirs visuels vont vers la cible)
    SilentAim = true,
    SilentHitChance = 100, -- % de chance de "hit" visuel
    
    -- Triggerbot
    Triggerbot = false,
    TriggerKey = Enum.KeyCode.T,
    TriggerDelay = 0.02,
    
    -- Whitelist/Blacklist
    Whitelist = {}, -- {"PlayerName1", "PlayerName2"}
    Blacklist = {}, -- {"PlayerName1"}
}

-- // STATE // --
local FOVCircle = Drawing.new("Circle")
local CurrentTarget = nil
local TriggerbotActive = false
local LastTrigger = 0

-- // UTILS // --
local function IsWhitelisted(player)
    if #Config.Whitelist == 0 then return true end
    for _, name in ipairs(Config.Whitelist) do
        if player.Name == name or player.DisplayName == name then return true end
    end
    return false
end

local function IsBlacklisted(player)
    for _, name in ipairs(Config.Blacklist) do
        if player.Name == name or player.DisplayName == name then return true end
    end
    return false
end

local function IsValidTarget(player)
    if not player or player == LocalPlayer then return false end
    if not IsWhitelisted(player) then return false end
    if IsBlacklisted(player) then return false end
    if Config.TeamCheck and player.Team and player.Team == LocalPlayer.Team then return false end
    
    local char = player.Character
    if not char then return false end
    
    local humanoid = char:FindFirstChild("Humanoid")
    if Config.AliveCheck and (not humanoid or humanoid.Health <= 0) then return false end
    
    local part = char:FindFirstChild(Config.TargetPart)
    if not part then return false end
    
    if Config.WallCheck then
        local origin = Camera.CFrame.Position
        local direction = (part.Position - origin).Unit * (part.Position - origin).Magnitude
        local rayParams = RaycastParams.new()
        rayParams.FilterType = Enum.RaycastFilterType.Blacklist
        rayParams.FilterDescendantsInstances = {LocalPlayer.Character, char}
        local result = workspace:Raycast(origin, direction, rayParams)
        if result and result.Instance and not result.Instance:IsDescendantOf(char) then
            return false -- Mur entre nous
        end
    end
    
    return true, part
end

local function GetClosestTarget()
    local closest = nil
    local closestDist = math.huge
    local closestScreenDist = math.huge
    local mousePos = UserInputService:GetMouseLocation()
    
    for _, player in ipairs(Players:GetPlayers()) do
        local valid, part = IsValidTarget(player)
        if valid and part then
            local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)
            if onScreen then
                local dist = (part.Position - Camera.CFrame.Position).Magnitude
                local screenDist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                
                local priority = Config.TargetPriority
                local checkDist = (priority == "Crosshair") and screenDist or dist
                local maxCheck = (priority == "Crosshair") and Config.FOV or math.huge
                
                if checkDist < maxCheck and checkDist < closestDist then
                    if priority == "Distance" then
                        closestDist = dist
                    elseif priority == "Crosshair" then
                        closestScreenDist = screenDist
                        closestDist = screenDist
                    elseif priority == "Health" then
                        local hum = player.Character:FindFirstChild("Humanoid")
                        closestDist = hum and hum.Health or math.huge
                    end
                    closest = {player = player, part = part, screenPos = Vector2.new(screenPos.X, screenPos.Y), dist = dist}
                end
            end
        end
    end
    return closest
end

local function UpdateFOVCircle()
    if not Config.ShowFOV then FOVCircle.Visible = false return end
    FOVCircle.Visible = true
    FOVCircle.Radius = Config.FOV
    FOVCircle.Thickness = 2
    FOVCircle.Color = Config.FOVColor
    FOVCircle.Filled = false
    FOVCircle.Transparency = 0.8
    FOVCircle.Position = UserInputService:GetMouseLocation()
end

-- // MAIN LOOP // --
RunService.RenderStepped:Connect(function()
    UpdateFOVCircle()
    
    if not Config.Enabled then 
        CurrentTarget = nil
        return 
    end
    
    -- Target acquisition
    local target = GetClosestTarget()
    CurrentTarget = target
    
    -- Aim Assist (Camera)
    if Config.AimAssist and target then
        local isHolding = UserInputService:IsMouseButtonPressed(Config.AimKey) or 
                          UserInputService:IsKeyDown(Enum.KeyCode.LeftControl)
        if isHolding then
            local targetPos = target.part.Position
            -- Prediction basique (velocity)
            local humanoid = target.player.Character:FindFirstChild("Humanoid")
            if humanoid and humanoid.MoveDirection.Magnitude > 0 then
                targetPos = targetPos + (humanoid.MoveDirection * humanoid.WalkSpeed * 0.08)
            end
            
            local currentCFrame = Camera.CFrame
            local targetCFrame = CFrame.new(currentCFrame.Position, targetPos)
            Camera.CFrame = currentCFrame:Lerp(targetCFrame, Config.Smoothness)
        end
    end
    
    -- Triggerbot
    if Config.Triggerbot and TriggerbotActive and target then
        local now = tick()
        if now - LastTrigger >= Config.TriggerDelay then
            mouse1press()
            task.wait(0.01)
            mouse1release()
            LastTrigger = now
        end
    end
end)

-- // SILENT AIM HOOK (Client Visual) // --
-- Hook FireServer/InvokeServer pour redirect visuel (ne fonctionne que sur jeux avec RemoteEvents non sécurisés)
local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
    if not Config.Enabled or not Config.SilentAim or not CurrentTarget then
        return oldNamecall(self, ...)
    end
    
    local method = getnamecallmethod()
    local args = {...}
    
    -- Patterns courants : FireServer, InvokeServer, Shoot, Fire, Attack
    if method == "FireServer" or method == "InvokeServer" then
        local scriptName = self.Name:lower()
        local parentName = self.Parent and self.Parent.Name:lower() or ""
        
        -- Détection d'arme/tir
        if scriptName:find("shoot") or scriptName:find("fire") or scriptName:find("attack") or 
           scriptName:find("gun") or scriptName:find("weapon") or scriptName:find("remot") or
           parentName:find("gun") or parentName:find("weapon") or parentName:find("tool") then
            
            -- Chance de hit
            if math.random(1, 100) <= Config.SilentHitChance then
                -- Modifie les arguments pour viser la cible
                for i, arg in ipairs(args) do
                    if typeof(arg) == "Vector3" then -- Position de tir
                        args[i] = CurrentTarget.part.Position
                    elseif typeof(arg) == "CFrame" then -- CFrame de tir
                        args[i] = CFrame.new(Camera.CFrame.Position, CurrentTarget.part.Position)
                    elseif typeof(arg) == "Ray" then -- Raycast
                        args[i] = Ray.new(Camera.CFrame.Position, (CurrentTarget.part.Position - Camera.CFrame.Position).Unit * 500)
                    elseif typeof(arg) == "Instance" and arg:IsA("BasePart") then -- Part touchée
                        args[i] = CurrentTarget.part
                    end
                end
                return oldNamecall(self, unpack(args))
            end
        end
    end
    
    return oldNamecall(self, ...)
end)

-- // INPUT HANDLING // --
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    
    -- Toggle Triggerbot
    if input.KeyCode == Config.TriggerKey then
        TriggerbotActive = not TriggerbotActive
        print("[AIM] Triggerbot: " .. (TriggerbotActive and "ON" or "OFF"))
    end
    
    -- Toggle Aim Assist (Insert)
    if input.KeyCode == Enum.KeyCode.Insert then
        Config.Enabled = not Config.Enabled
        Config.AimAssist = Config.Enabled
        Config.SilentAim = Config.Enabled
        print("[AIM] Global: " .. (Config.Enabled and "ON" or "OFF"))
    end
    
    -- Toggle Silent Aim (Delete)
    if input.KeyCode == Enum.KeyCode.Delete then
        Config.SilentAim = not Config.SilentAim
        print("[AIM] Silent Aim: " .. (Config.SilentAim and "ON" or "OFF"))
    end
end)

UserInputService.InputEnded:Connect(function(input, gp)
    if input.KeyCode == Config.TriggerKey then
        TriggerbotActive = false
    end
end)

-- // CLEANUP // --
local function Cleanup()
    FOVCircle:Remove()
    if oldNamecall then hookmetamethod(game, "__namecall", oldNamecall) end
end

game:GetService("Players").PlayerRemoving:Connect(function(p)
    if p == LocalPlayer then Cleanup() end
end)

-- // GUI SIMPLE (optionnel) // --
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AimAssistUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 220, 0, 180)
Frame.Position = UDim2.new(1, -230, 0, 20)
Frame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
Frame.BorderSizePixel = 0
Frame.Active = true
Frame.Draggable = true
Frame.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 8)
UICorner.Parent = Frame

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -10, 0, 30)
Title.Position = UDim2.new(0, 5, 0, 5)
Title.BackgroundTransparency = 1
Title.Text = "🎯 AIM ASSIST / SILENT AIM"
Title.TextColor3 = Color3.fromRGB(255, 80, 80)
Title.TextSize = 14
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Frame

local function MakeToggle(name, yPos, callback, default)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -20, 0, 28)
    btn.Position = UDim2.new(0, 10, 0, yPos)
    btn.BackgroundColor3 = default and Color3.fromRGB(60, 180, 80) or Color3.fromRGB(180, 60, 60)
    btn.BorderSizePixel = 0
    btn.Text = "  " .. name .. ": " .. (default and "ON" or "OFF")
    btn.TextColor3 = Color3.new(1,1,1)
    btn.TextSize = 13
    btn.Font = Enum.Font.GothamSemibold
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.Parent = Frame
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    
    btn.MouseButton1Click:Connect(function()
        default = not default
        btn.BackgroundColor3 = default and Color3.fromRGB(60, 180, 80) or Color3.fromRGB(180, 60, 60)
        btn.Text = "  " .. name .. ": " .. (default and "ON" or "OFF")
        callback(default)
    end)
    return btn
end

local function MakeSlider(name, yPos, min, max, default, callback)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -20, 0, 20)
    label.Position = UDim2.new(0, 10, 0, yPos)
    label.BackgroundTransparency = 1
    label.Text = name .. ": " .. default
    label.TextColor3 = Color3.new(1,1,1)
    label.TextSize = 12
    label.Font = Enum.Font.Gotham
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = Frame
    
    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(1, -20, 0, 6)
    bar.Position = UDim2.new(0, 10, 0, yPos + 20)
    bar.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    bar.BorderSizePixel = 0
    bar.Parent = Frame
    Instance.new("UICorner", bar).CornerRadius = UDim.new(0, 3)
    
    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
    fill.BorderSizePixel = 0
    fill.Parent = bar
    Instance.new("UICorner", fill).CornerRadius = UDim.new(0, 3)
    
    local dragging = false
    bar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)
    RunService.RenderStepped:Connect(function()
        if dragging then
            local mouse = UserInputService:GetMouseLocation()
            local rel = math.clamp((mouse.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
            local val = math.floor(min + (max - min) * rel)
            fill.Size = UDim2.new(rel, 0, 1, 0)
            label.Text = name .. ": " .. val
            callback(val)
        end
    end)
end

MakeToggle("Enabled", 40, function(v) Config.Enabled = v; Config.AimAssist = v; Config.SilentAim = v end, true)
MakeToggle("Team Check", 75, function(v) Config.TeamCheck = v end, true)
MakeToggle("Wall Check", 110, function(v) Config.WallCheck = v end, true)
MakeToggle("Silent Aim", 145, function(v) Config.SilentAim = v end, true)

-- Sliders (ajoutés plus bas si besoin)
MakeSlider("FOV", 180, 30, 500, Config.FOV, function(v) Config.FOV = v end)
MakeSlider("Smoothness", 220, 1, 50, math.floor(Config.Smoothness * 100), function(v) Config.Smoothness = v / 100 end)
MakeSlider("Hit Chance %", 260, 0, 100, Config.SilentHitChance, function(v) Config.SilentHitChance = v end)

print("[AIM] Loaded. INSERT = Toggle All | DELETE = Toggle Silent Aim | T = Triggerbot | Right Click = Aim Assist")
print("[AIM] GUI draggable top-right. Check console (F9) for debug.")
