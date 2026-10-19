-- // NEON RAGE CHEAT — FIXED EDITION // --
-- // Full Rage | ESP | AimBot | Movement | Visuals | Sexy Neon UI // --
-- // Fixed: HealthBar Text spam, Font Enum, RenderStepped leaks // --

if getgenv().NeonRageLoaded then
    getgenv().NeonRageUnload()
end
getgenv().NeonRageLoaded = true

-- // SERVICES // --
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")
local Lighting = game:GetService("Lighting")
local SoundService = game:GetService("SoundService")
local StarterGui = game:GetService("StarterGui")

-- // VARIABLES // --
local Config = {
    Aimbot = { Enabled = true, SilentAim = true, CameraAim = false, Triggerbot = false,
        AimKey = Enum.UserInputType.MouseButton2, ToggleMode = false,
        FOV = 120, ShowFOV = true, FOVColor = Color3.fromRGB(255, 50, 120),
        TargetPart = "Head", Priority = "Crosshair",
        TeamCheck = true, WallCheck = true, AliveCheck = true, MaxDist = 1000,
        HitChance = 100, Prediction = true, PredVelocity = true, PredGravity = true,
        ProjectileSpeed = 99999, Smoothness = 0.02, Humanize = true, ReactionDelay = 0.05,
        OvershootCorr = 0.15, Jitter = {Enabled = true, Intensity = 0.3, Freq = 0.08} },
    
    ESP = { Enabled = true, TeamCheck = true, MaxDist = 3000,
        Box = {Enabled = true, Type = "Corner", Color = Color3.fromRGB(255, 50, 120), Thickness = 1.5, Filled = false, FillTransparency = 0.85},
        Skeleton = {Enabled = true, Color = Color3.fromRGB(255, 255, 255), Thickness = 1.5},
        HealthBar = {Enabled = true, Side = "Left", ShowText = true},
        Name = {Enabled = true, Color = Color3.fromRGB(255, 255, 255), Size = 13, Outline = true},
        Distance = {Enabled = true, Color = Color3.fromRGB(200, 200, 200), Size = 12},
        Tracer = {Enabled = true, Color = Color3.fromRGB(255, 50, 120), Thickness = 1, Origin = "Bottom"},
        Chams = {Enabled = true, FillColor = Color3.fromRGB(255, 50, 120), OutlineColor = Color3.fromRGB(255, 255, 255), FillTrans = 0.6, OutlineTrans = 0},
        OffscreenArrows = {Enabled = true, Size = 24, Color = Color3.fromRGB(255, 50, 120), Radius = 200},
        RainbowMode = false, RainbowSpeed = 1.5 },
    
    Movement = { SpeedHack = {Enabled = false, Speed = 28, Method = "CFrame"},
        Fly = {Enabled = false, Speed = 50, Keybind = Enum.KeyCode.F},
        NoClip = {Enabled = false, Keybind = Enum.KeyCode.N},
        InfiniteJump = {Enabled = false},
        Bhop = {Enabled = false, Height = 7.5},
        AirWalk = {Enabled = false, Keybind = Enum.KeyCode.V},
        SwimFly = {Enabled = false},
        AutoParry = {Enabled = false, Range = 20} },
    
    Combat = { RapidFire = false, NoRecoil = false, NoSpread = false, InfiniteAmmo = false, AutoReload = false,
        HitSound = {Enabled = true, SoundId = "rbxassetid://6831473140", Volume = 1.5},
        HitMarker = {Enabled = true, Color = Color3.fromRGB(255, 50, 120), Time = 0.3},
        KillSound = {Enabled = true, SoundId = "rbxassetid://6831473140", Volume = 2} },
    
    Visuals = { Crosshair = {Enabled = true, Type = "Dot", Size = 8, Gap = 4, Thickness = 1.5, Color = Color3.fromRGB(255, 50, 120), Rainbow = false, RotationSpeed = 0},
        RainbowGun = false, FullBright = false, NoFog = false, Ambient = Color3.fromRGB(255, 255, 255),
        FOVChanger = {Enabled = false, Value = 90}, RemoveCamShake = true },
    
    Protection = { AntiAim = {Enabled = false, Type = "Spin", Speed = 20},
        AntiFling = true, AntiVoid = true, AutoRespawn = false, ChatSpy = true, AntiAFK = true },
    
    UI = { Theme = "Neon", AccentColor = Color3.fromRGB(255, 50, 120), Keybind = Enum.KeyCode.Insert,
        Watermark = true, KeybindsList = true, SpectatorList = true }
}

local State = {
    AimbotActive = false, TriggerActive = false, FlyActive = false, NoClipActive = false,
    AirWalkActive = false, CurrentTarget = nil, LastTarget = nil, ReactionTimer = 0,
    JitterTimer = 0, JitterOffset = Vector2.new(0,0), Connections = {}, Drawings = {},
    ESPObjects = {}, ChamsObjects = {}, OriginalLighting = {}, OriginalCamera = {},
    FlyBodyVel = nil, FlyBodyGyro = nil, AirWalkPart = nil, BhopConn = nil,
    HitMarkers = {}, KillFeed = {}, LastKillTime = 0,
    CrosshairParts = {}, DynamicCrosshairConn = nil
}

local Theme = {
    Background = Color3.fromRGB(12, 12, 18),
    Surface = Color3.fromRGB(18, 18, 26),
    SurfaceHover = Color3.fromRGB(24, 24, 34),
    Border = Color3.fromRGB(40, 40, 60),
    Accent = Config.UI.AccentColor,
    AccentDim = Color3.fromRGB(180, 30, 80),
    Text = Color3.fromRGB(245, 245, 255),
    TextDim = Color3.fromRGB(160, 160, 180),
    Red = Color3.fromRGB(255, 60, 90),
    Green = Color3.fromRGB(60, 220, 120),
    Yellow = Color3.fromRGB(255, 200, 50),
    Cyan = Color3.fromRGB(50, 220, 255),
    Purple = Color3.fromRGB(180, 80, 255)
}

-- // UTILS // --
local function Lerp(a, b, t) return a + (b - a) * t end
local function Clamp(v, min, max) return math.max(min, math.min(max, v)) end
local function RandomVec2(range) return Vector2.new((math.random()-0.5)*range, (math.random()-0.5)*range) end
local function GetRainbow(speed) local h = (tick()*speed)%1 return Color3.fromHSV(h, 0.8, 1) end
local function WorldToScreen(pos) local s, v = Camera:WorldToViewportPoint(pos) return Vector2.new(s.X, s.Y), v, s.Z end
local function GetMousePos() return UserInputService:GetMouseLocation() end
local function IsKeyDown(key) return UserInputService:IsKeyDown(key) end
local function IsMouseDown(btn) return UserInputService:IsMouseButtonPressed(btn) end
local function SafeCall(fn, ...) local s, r = pcall(fn, ...) if not s then warn("[NEON] Error:", r) end return r end

-- // CONFIG SAVE/LOAD // --
local CONFIG_FILE = "NeonRage_Config.json"
local function SaveConfig()
    local save = {}
    for cat, tbl in pairs(Config) do
        save[cat] = {}
        for k, v in pairs(tbl) do
            if typeof(v) == "Color3" then save[cat][k] = {R=v.R, G=v.G, B=v.B}
            elseif typeof(v) == "EnumItem" then save[cat][k] = tostring(v)
            elseif type(v) == "table" then
                save[cat][k] = {}
                for k2, v2 in pairs(v) do
                    if typeof(v2) == "Color3" then save[cat][k][k2] = {R=v2.R, G=v2.G, B=v2.B}
                    elseif typeof(v2) == "EnumItem" then save[cat][k][k2] = tostring(v2)
                    else save[cat][k][k2] = v2 end
                end
            else save[cat][k] = v end
        end
    end
    writefile(CONFIG_FILE, HttpService:JSONEncode(save))
end

local function LoadConfig()
    if not isfile(CONFIG_FILE) then return end
    local ok, data = pcall(function() return HttpService:JSONDecode(readfile(CONFIG_FILE)) end)
    if not ok then return end
    local function apply(tbl, data)
        for k, v in pairs(data) do
            if typeof(tbl[k]) == "Color3" and type(v) == "table" and v.R then
                tbl[k] = Color3.new(v.R, v.G, v.B)
            elseif typeof(tbl[k]) == "EnumItem" and type(v) == "string" then
                local enumStr = v:match("Enum%.(.+)")
                if enumStr then
                    local parts = string.split(enumStr, ".")
                    if #parts == 2 then tbl[k] = Enum[parts[1]][parts[2]] end
                end
            elseif type(tbl[k]) == "table" and type(v) == "table" then
                apply(tbl[k], v)
            else tbl[k] = v end
        end
    end
    apply(Config, data)
    print("[NEON] Config loaded.")
end

-- // ESP ENGINE // --
local function CreateDrawing(class, props)
    local d = Drawing.new(class)
    for k, v in pairs(props) do d[k] = v end
    table.insert(State.Drawings, d)
    return d
end

local function GetDrawingFont()
    -- Compatibilité: nouveaux exécuteurs (Drawing.Fonts) / anciens (nombre)
    if Drawing.Fonts then return Drawing.Fonts.Plex end
    return 2 -- Fallback legacy (0=UI, 1=System, 2=Plex, 3=Monospace)
end

local function CreateESP(player)
    if player == LocalPlayer then return end
    local font = GetDrawingFont()
    local esp = {
        Box = {Outline = CreateDrawing("Square", {Visible=false, Thickness=3, Filled=false, Color=Color3.new(0,0,0)}),
               Main = CreateDrawing("Square", {Visible=false, Thickness=1.5, Filled=false})},
        BoxFill = CreateDrawing("Square", {Visible=false, Filled=true}),
        Skeleton = {},
        HealthBar = {Outline = CreateDrawing("Square", {Visible=false, Thickness=1, Filled=true, Color=Color3.new(0,0,0)}),
                     Main = CreateDrawing("Square", {Visible=false, Filled=true}),
                     Text = CreateDrawing("Text", {Visible=false, Center=true, Outline=true, Font=font, Size=11})},
        Name = CreateDrawing("Text", {Visible=false, Center=true, Outline=true, Font=font, Size=13}),
        Distance = CreateDrawing("Text", {Visible=false, Center=true, Outline=true, Font=font, Size=12}),
        Tracer = CreateDrawing("Line", {Visible=false, Thickness=1}),
        OffscreenArrow = CreateDrawing("Triangle", {Visible=false, Filled=true, Thickness=1}),
        Chams = nil
    }
    State.ESPObjects[player] = esp
    
    local bones = {
        {"Head", "UpperTorso"}, {"UpperTorso", "LowerTorso"}, {"UpperTorso", "LeftUpperArm"}, {"LeftUpperArm", "LeftLowerArm"}, {"LeftLowerArm", "LeftHand"},
        {"UpperTorso", "RightUpperArm"}, {"RightUpperArm", "RightLowerArm"}, {"RightLowerArm", "RightHand"},
        {"LowerTorso", "LeftUpperLeg"}, {"LeftUpperLeg", "LeftLowerLeg"}, {"LeftLowerLeg", "LeftFoot"},
        {"LowerTorso", "RightUpperLeg"}, {"RightUpperLeg", "RightLowerLeg"}, {"RightLowerLeg", "RightFoot"}
    }
    for _, bone in ipairs(bones) do
        esp.Skeleton[bone[1].."-"..bone[2]] = CreateDrawing("Line", {Visible=false, Thickness=1.5})
    end
end

local function RemoveESP(player)
    local esp = State.ESPObjects[player]
    if not esp then return end
    for _, v in pairs(esp) do
        if type(v) == "table" then
            for _, d in pairs(v) do if d.Remove then d:Remove() end end
        elseif v.Remove then v:Remove() end
    end
    if esp.Chams then
        for _, h in pairs(esp.Chams) do if h.Destroy then h:Destroy() end end
    end
    State.ESPObjects[player] = nil
end

local function UpdateChams(player, char)
    local esp = State.ESPObjects[player]
    if not esp then return end
    if not Config.ESP.Chams.Enabled then
        if esp.Chams then for _, h in pairs(esp.Chams) do h:Destroy() end esp.Chams = nil end
        return
    end
    if not esp.Chams then esp.Chams = {} end
    for _, part in pairs(char:GetDescendants()) do
        if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
            if not esp.Chams[part] then
                local hl = Instance.new("Highlight")
                hl.Adornee = part
                hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                hl.Parent = part
                esp.Chams[part] = hl
            end
            local hl = esp.Chams[part]
            local c = Config.ESP.RainbowMode and GetRainbow(Config.ESP.RainbowSpeed) or Config.ESP.Chams.FillColor
            local oc = Config.ESP.RainbowMode and GetRainbow(Config.ESP.RainbowSpeed + 0.3) or Config.ESP.Chams.OutlineColor
            hl.FillColor = c
            hl.OutlineColor = oc
            hl.FillTransparency = Config.ESP.Chams.FillTrans
            hl.OutlineTransparency = Config.ESP.Chams.OutlineTrans
        end
    end
end

-- // AIMBOT LOGIC // --
local function IsWhitelisted(plr) return true end
local function IsBlacklisted(plr) return false end

local function IsValidTarget(plr)
    if not plr or plr == LocalPlayer then return false end
    if not IsWhitelisted(plr) or IsBlacklisted(plr) then return false end
    if Config.Aimbot.TeamCheck and plr.Team and plr.Team == LocalPlayer.Team then return false end
    
    local char = plr.Character
    if not char then return false end
    local hum = char:FindFirstChild("Humanoid")
    if Config.Aimbot.AliveCheck and (not hum or hum.Health <= 0) then return false end
    
    local part = char:FindFirstChild(Config.Aimbot.TargetPart)
    if not part then return false end
    
    local dist = (part.Position - Camera.CFrame.Position).Magnitude
    if dist > Config.Aimbot.MaxDist then return false end
    
    if Config.Aimbot.WallCheck then
        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        params.FilterDescendantsInstances = {LocalPlayer.Character, char}
        params.IgnoreWater = true
        local result = workspace:Raycast(Camera.CFrame.Position, (part.Position - Camera.CFrame.Position).Unit * dist, params)
        if result and result.Instance and not result.Instance:IsDescendantOf(char) then return false end
    end
    return true, part, char, hum
end

local function GetBestTarget()
    local mousePos = GetMousePos()
    local best, bestScore = nil, math.huge
    
    for _, plr in ipairs(Players:GetPlayers()) do
        local valid, part, char, hum = IsValidTarget(plr)
        if valid then
            local screenPos, onScreen, depth = WorldToScreen(part.Position)
            if onScreen and depth > 0 then
                local screenDist = (screenPos - mousePos).Magnitude
                local worldDist = (part.Position - Camera.CFrame.Position).Magnitude
                local score = (Config.Aimbot.Priority == "Crosshair" and screenDist) or
                             (Config.Aimbot.Priority == "Distance" and worldDist) or
                             (Config.Aimbot.Priority == "Health" and (hum.MaxHealth - hum.Health)) or math.huge
                
                if Config.Aimbot.Priority == "Crosshair" and screenDist > Config.Aimbot.FOV then score = math.huge end
                
                if score < bestScore then
                    bestScore = score
                    best = {player=plr, part=part, char=char, hum=hum, screenPos=screenPos, worldDist=worldDist}
                end
            end
        end
    end
    return best
end

local function PredictPosition(target)
    if not Config.Aimbot.Prediction then return target.part.Position end
    local part, char, hum = target.part, target.char, target.hum
    local origin = Camera.CFrame.Position
    local targetPos = part.Position
    local dist = (targetPos - origin).Magnitude
    local speed = Config.Aimbot.ProjectileSpeed
    if speed >= 99999 then return targetPos end
    local timeToHit = dist / speed
    
    if Config.Aimbot.PredVelocity and hum and hum.MoveDirection.Magnitude > 0 then
        targetPos = targetPos + hum.MoveDirection * hum.WalkSpeed * timeToHit
        dist = (targetPos - origin).Magnitude
        timeToHit = dist / speed
    end
    if Config.Aimbot.PredGravity and Config.Aimbot.ProjectileGravity > 0 then
        targetPos = targetPos - Vector3.new(0, 0.5 * Config.Aimbot.ProjectileGravity * timeToHit^2, 0)
    end
    return targetPos
end

-- // SILENT AIM HOOK // --
local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
    if not Config.Aimbot.Enabled or not Config.Aimbot.SilentAim or not State.CurrentTarget then
        return oldNamecall(self, ...)
    end
    local method = getnamecallmethod()
    local args = {...}
    if method == "FireServer" or method == "InvokeServer" then
        local name = self.Name:lower()
        local pname = self.Parent and self.Parent.Name:lower() or ""
        if name:find("shoot") or name:find("fire") or name:find("attack") or name:find("gun") or name:find("weapon") or name:find("remot") or
           pname:find("gun") or pname:find("weapon") or pname:find("tool") then
            if math.random(1, 100) <= Config.Aimbot.HitChance then
                local predPos = PredictPosition(State.CurrentTarget)
                for i, arg in ipairs(args) do
                    if typeof(arg) == "Vector3" then args[i] = predPos
                    elseif typeof(arg) == "CFrame" then args[i] = CFrame.new(Camera.CFrame.Position, predPos)
                    elseif typeof(arg) == "Ray" then args[i] = Ray.new(Camera.CFrame.Position, (predPos - Camera.CFrame.Position).Unit * 500)
                    elseif typeof(arg) == "Instance" and arg:IsA("BasePart") then args[i] = State.CurrentTarget.part end
                end
                return oldNamecall(self, unpack(args))
            end
        end
    end
    return oldNamecall(self, ...)
end)

-- // HIT SOUND / MARKER // --
local function PlayHitSound()
    if not Config.Combat.HitSound.Enabled then return end
    local s = Instance.new("Sound")
    s.SoundId = Config.Combat.HitSound.SoundId
    s.Volume = Config.Combat.HitSound.Volume
    s.PlayOnRemove = true
    s.Parent = SoundService
    s:Destroy()
end

local function ShowHitMarker(pos)
    if not Config.Combat.HitMarker.Enabled then return end
    local screenPos, onScreen = WorldToScreen(pos)
    if not onScreen then return end
    local marker = {pos = screenPos, time = tick(), duration = Config.Combat.HitMarker.Time}
    table.insert(State.HitMarkers, marker)
end

-- // MAIN GAME LOOP // --
local lastFrame = tick()
State.Connections.MainLoop = RunService.RenderStepped:Connect(function()
    local now = tick()
    local dt = now - lastFrame
    lastFrame = now
    
    -- Rainbow update
    if Config.ESP.RainbowMode or Config.Visuals.Crosshair.Rainbow or Config.Visuals.RainbowGun then
        Theme.Accent = GetRainbow(Config.ESP.RainbowSpeed)
        Config.UI.AccentColor = Theme.Accent
    end
    
    -- // AIMBOT // --
    if Config.Aimbot.Enabled then
        local aimKeyDown = IsMouseDown(Config.Aimbot.AimKey)
        if Config.Aimbot.ToggleMode then
            if aimKeyDown and not State.AimbotActive then State.AimbotActive = true
            elseif aimKeyDown and State.AimbotActive then State.AimbotActive = false end
        else State.AimbotActive = aimKeyDown end
        
        local target = GetBestTarget()
        State.CurrentTarget = target
        
        if State.AimbotActive and target then
            if target ~= State.LastTarget then
                State.ReactionTimer = Config.Aimbot.Humanize and Config.Aimbot.ReactionDelay or 0
                State.LastTarget = target
            end
            
            if State.ReactionTimer > 0 then
                State.ReactionTimer = State.ReactionTimer - dt
            else
                local predPos = PredictPosition(target)
                local screenPos, onScreen = WorldToScreen(predPos)
                if onScreen then
                    local mousePos = GetMousePos()
                    local delta = screenPos - mousePos
                    
                    if Config.Aimbot.Humanize then
                        local smooth = Config.Aimbot.Smoothness
                        if Config.Aimbot.OvershootCorr > 0 and State.LastTarget then
                            local lastDelta = screenPos - State.LastTarget
                            if lastDelta:Dot(delta) < 0 then smooth = smooth * (1 - Config.Aimbot.OvershootCorr) end
                        end
                        delta = delta * smooth
                        
                        if Config.Aimbot.Jitter.Enabled then
                            State.JitterTimer = State.JitterTimer + dt
                            if State.JitterTimer >= Config.Aimbot.Jitter.Freq then
                                State.JitterTimer = 0
                                State.JitterOffset = RandomVec2(Config.Aimbot.Jitter.Intensity)
                            end
                            delta = delta + State.JitterOffset
                        end
                    end
                    
                    if Config.Aimbot.CameraAim then
                        local cf = Camera.CFrame
                        Camera.CFrame = cf:Lerp(CFrame.new(cf.Position, predPos), Config.Aimbot.Smoothness * 2)
                    end
                    if mousemoverel and not Config.Aimbot.CameraAim then
                        mousemoverel(delta.X, delta.Y)
                    end
                    State.LastTarget = screenPos
                end
            end
        else
            State.ReactionTimer = 0
            State.LastTarget = nil
        end
    end
    
    -- // TRIGGERBOT // --
    if Config.Aimbot.Triggerbot and IsKeyDown(Config.Aimbot.TriggerKey) then
        local target = GetBestTarget()
        if target then
            local predPos = PredictPosition(target)
            local screenPos, onScreen = WorldToScreen(predPos)
            if onScreen and (screenPos - GetMousePos()).Magnitude <= 3 then
                mouse1press()
                task.wait(0.01)
                mouse1release()
            end
        end
    end
    
    -- // MOVEMENT // --
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChild("Humanoid")
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    
    if Config.Movement.SpeedHack.Enabled and hum and hrp then
        local moveDir = hum.MoveDirection
        if moveDir.Magnitude > 0 then
            if Config.Movement.SpeedHack.Method == "CFrame" then
                hrp.CFrame = hrp.CFrame + moveDir.Unit * Config.Movement.SpeedHack.Speed * dt
            elseif Config.Movement.SpeedHack.Method == "Velocity" then
                hrp.Velocity = Vector3.new(moveDir.X * Config.Movement.SpeedHack.Speed, hrp.Velocity.Y, moveDir.Z * Config.Movement.SpeedHack.Speed)
            end
        end
    end
    
    if Config.Movement.Fly.Enabled then
        if IsKeyDown(Config.Movement.Fly.Keybind) and not State.FlyActive then
            State.FlyActive = true
            State.FlyBodyVel = Instance.new("BodyVelocity")
            State.FlyBodyVel.MaxForce = Vector3.new(9e9, 9e9, 9e9)
            State.FlyBodyVel.Velocity = Vector3.new(0,0,0)
            State.FlyBodyVel.Parent = hrp
            State.FlyBodyGyro = Instance.new("BodyGyro")
            State.FlyBodyGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
            State.FlyBodyGyro.CFrame = hrp.CFrame
            State.FlyBodyGyro.Parent = hrp
        elseif not IsKeyDown(Config.Movement.Fly.Keybind) and State.FlyActive then
            State.FlyActive = false
            if State.FlyBodyVel then State.FlyBodyVel:Destroy() end
            if State.FlyBodyGyro then State.FlyBodyGyro:Destroy() end
        end
        if State.FlyActive and hrp then
            local camCF = Camera.CFrame
            local move = Vector3.new()
            if IsKeyDown(Enum.KeyCode.W) then move = move + camCF.LookVector end
            if IsKeyDown(Enum.KeyCode.S) then move = move - camCF.LookVector end
            if IsKeyDown(Enum.KeyCode.A) then move = move - camCF.RightVector end
            if IsKeyDown(Enum.KeyCode.D) then move = move + camCF.RightVector end
            if IsKeyDown(Enum.KeyCode.Space) then move = move + Vector3.new(0,1,0) end
            if IsKeyDown(Enum.KeyCode.LeftShift) then move = move - Vector3.new(0,1,0) end
            State.FlyBodyVel.Velocity = move.Magnitude > 0 and move.Unit * Config.Movement.Fly.Speed or Vector3.new(0,0,0)
            State.FlyBodyGyro.CFrame = camCF
        end
    end
    
    if Config.Movement.NoClip.Enabled then
        if IsKeyDown(Config.Movement.NoClip.Keybind) and not State.NoClipActive then State.NoClipActive = true
        elseif IsKeyDown(Config.Movement.NoClip.Keybind) and State.NoClipActive then State.NoClipActive = false end
        if State.NoClipActive and char then
            for _, part in pairs(char:GetDescendants()) do
                if part:IsA("BasePart") then part.CanCollide = false end
            end
        end
    end
    
    if Config.Movement.InfiniteJump.Enabled and hum then
        hum.JumpPower = 50
        if IsKeyDown(Enum.KeyCode.Space) then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
    
    if Config.Movement.Bhop.Enabled and hum and hrp then
        if hum.FloorMaterial ~= Enum.Material.Air and IsKeyDown(Enum.KeyCode.Space) then
            hrp.Velocity = Vector3.new(hrp.Velocity.X, Config.Movement.Bhop.Height, hrp.Velocity.Z)
        end
    end
    
    if Config.Movement.AirWalk.Enabled then
        if IsKeyDown(Config.Movement.AirWalk.Keybind) and not State.AirWalkActive then
            State.AirWalkActive = true
            State.AirWalkPart = Instance.new("Part")
            State.AirWalkPart.Size = Vector3.new(10, 1, 10)
            State.AirWalkPart.Transparency = 1
            State.AirWalkPart.Anchored = true
            State.AirWalkPart.CanCollide = true
            State.AirWalkPart.Parent = workspace
        elseif IsKeyDown(Config.Movement.AirWalk.Keybind) and State.AirWalkActive then
            State.AirWalkActive = false
            if State.AirWalkPart then State.AirWalkPart:Destroy() end
        end
        if State.AirWalkActive and hrp and State.AirWalkPart then
            State.AirWalkPart.CFrame = CFrame.new(hrp.Position - Vector3.new(0, 3.5, 0))
        end
    end
    
    -- // VISUALS // --
    if Config.Visuals.FullBright then
        Lighting.Brightness = 2
        Lighting.ClockTime = 14
        Lighting.FogEnd = 100000
        Lighting.GlobalShadows = false
        Lighting.OutdoorAmbient = Color3.new(1,1,1)
    end
    if Config.Visuals.NoFog then Lighting.FogEnd = 100000 end
    if Config.Visuals.Ambient then Lighting.Ambient = Config.Visuals.Ambient end
    
    if Config.Visuals.FOVChanger.Enabled then Camera.FieldOfView = Config.Visuals.FOVChanger.Value end
    
    if Config.Visuals.RemoveCamShake then
        Camera.CFrame = Camera.CFrame * CFrame.new(0,0,0)
    end
    
    -- // ESP RENDER // --
    if Config.ESP.Enabled then
        for plr, esp in pairs(State.ESPObjects) do
            if plr and plr.Parent then
                local valid, part, char, hum = IsValidTarget(plr)
                local show = valid and (part.Position - Camera.CFrame.Position).Magnitude <= Config.ESP.MaxDist
                
                if show and char and part then
                    local cf, size = char:GetBoundingBox()
                    local corners = {}
                    local min = cf.Position - size/2
                    local max = cf.Position + size/2
                    for x = 0, 1 do for y = 0, 1 do for z = 0, 1 do
                        table.insert(corners, cf * CFrame.new((x-0.5)*size.X, (y-0.5)*size.Y, (z-0.5)*size.Z))
                    end end end
                    
                    local screenCorners = {}
                    local onScreen = false
                    for _, corner in ipairs(corners) do
                        local s, v = WorldToScreen(corner.Position)
                        table.insert(screenCorners, s)
                        if v then onScreen = true end
                    end
                    
                    if onScreen then
                        local minX, minY = math.huge, math.huge
                        local maxX, maxY = -math.huge, -math.huge
                        for _, s in ipairs(screenCorners) do
                            minX = math.min(minX, s.X); minY = math.min(minY, s.Y)
                            maxX = math.max(maxX, s.X); maxY = math.max(maxY, s.Y)
                        end
                        local w, h = maxX - minX, maxY - minY
                        local centerX, centerY = (minX + maxX)/2, (minY + maxY)/2
                        
                        local color = Config.ESP.RainbowMode and GetRainbow(Config.ESP.RainbowSpeed) or Config.ESP.Box.Color
                        if plr.Team and Config.ESP.TeamCheck then color = plr.Team.TeamColor.Color end
                        
                        -- Box
                        if Config.ESP.Box.Enabled then
                            esp.Box.Main.Visible = true
                            esp.Box.Main.Size = Vector2.new(w, h)
                            esp.Box.Main.Position = Vector2.new(minX, minY)
                            esp.Box.Main.Color = color
                            esp.Box.Main.Thickness = Config.ESP.Box.Thickness
                            esp.Box.Outline.Visible = true
                            esp.Box.Outline.Size = Vector2.new(w, h)
                            esp.Box.Outline.Position = Vector2.new(minX, minY)
                            if Config.ESP.Box.Filled then
                                esp.BoxFill.Visible = true
                                esp.BoxFill.Size = Vector2.new(w, h)
                                esp.BoxFill.Position = Vector2.new(minX, minY)
                                esp.BoxFill.Color = color
                                esp.BoxFill.Transparency = Config.ESP.Box.FillTransparency
                            else esp.BoxFill.Visible = false end
                        else esp.Box.Main.Visible = false; esp.Box.Outline.Visible = false; esp.BoxFill.Visible = false end
                        
                        -- Skeleton
                        if Config.ESP.Skeleton.Enabled then
                            local skeletonColor = Config.ESP.RainbowMode and GetRainbow(Config.ESP.RainbowSpeed + 0.5) or Config.ESP.Skeleton.Color
                            local function drawBone(p1, p2)
                                local p1pos = char:FindFirstChild(p1)
                                local p2pos = char:FindFirstChild(p2)
                                if p1pos and p2pos then
                                    local s1, v1 = WorldToScreen(p1pos.Position)
                                    local s2, v2 = WorldToScreen(p2pos.Position)
                                    if v1 and v2 then
                                        local line = esp.Skeleton[p1.."-"..p2]
                                        if line then
                                            line.Visible = true
                                            line.From = s1
                                            line.To = s2
                                            line.Color = skeletonColor
                                            line.Thickness = Config.ESP.Skeleton.Thickness
                                        end
                                    else
                                        local line = esp.Skeleton[p1.."-"..p2]
                                        if line then line.Visible = false end
                                    end
                                end
                            end
                            drawBone("Head", "UpperTorso")
                            drawBone("UpperTorso", "LowerTorso")
                            drawBone("UpperTorso", "LeftUpperArm"); drawBone("LeftUpperArm", "LeftLowerArm"); drawBone("LeftLowerArm", "LeftHand")
                            drawBone("UpperTorso", "RightUpperArm"); drawBone("RightUpperArm", "RightLowerArm"); drawBone("RightLowerArm", "RightHand")
                            drawBone("LowerTorso", "LeftUpperLeg"); drawBone("LeftUpperLeg", "LeftLowerLeg"); drawBone("LeftLowerLeg", "LeftFoot")
                            drawBone("LowerTorso", "RightUpperLeg"); drawBone("RightUpperLeg", "RightLowerLeg"); drawBone("RightLowerLeg", "RightFoot")
                        else for _, line in pairs(esp.Skeleton) do line.Visible = false end end
                        
                        -- Health Bar
                        if Config.ESP.HealthBar.Enabled and hum then
                            local barH = h * (hum.Health / hum.MaxHealth)
                            local barX = Config.ESP.HealthBar.Side == "Left" and minX - 6 or maxX + 2
                            esp.HealthBar.Outline.Visible = true
                            esp.HealthBar.Outline.Size = Vector2.new(4, h)
                            esp.HealthBar.Outline.Position = Vector2.new(barX, minY)
                            esp.HealthBar.Main.Visible = true
                            esp.HealthBar.Main.Size = Vector2.new(2, barH)
                            esp.HealthBar.Main.Position = Vector2.new(barX + 1, maxY - barH)
                            esp.HealthBar.Main.Color = Color3.fromHSV((hum.Health/hum.MaxHealth)*0.33, 1, 1)
                            if Config.ESP.HealthBar.ShowText then
                                esp.HealthBar.Text.Visible = true
                                esp.HealthBar.Text.Position = Vector2.new(barX + 1, minY - 12)
                                -- FIX: tostring() ici
                                esp.HealthBar.Text.Text = tostring(math.floor(hum.Health))
                                esp.HealthBar.Text.Color = Color3.new(1,1,1)
                            else esp.HealthBar.Text.Visible = false end
                        else esp.HealthBar.Outline.Visible = false; esp.HealthBar.Main.Visible = false; esp.HealthBar.Text.Visible = false end
                        
                        -- Name
                        if Config.ESP.Name.Enabled then
                            esp.Name.Visible = true
                            esp.Name.Position = Vector2.new(centerX, minY - 18)
                            esp.Name.Text = plr.DisplayName ~= plr.Name and plr.DisplayName.." (@"..plr.Name..")" or plr.Name
                            esp.Name.Color = Config.ESP.RainbowMode and GetRainbow(Config.ESP.RainbowSpeed + 0.2) or Config.ESP.Name.Color
                            esp.Name.Size = Config.ESP.Name.Size
                            esp.Name.Outline = Config.ESP.Name.Outline
                        else esp.Name.Visible = false end
                        
                        -- Distance
                        if Config.ESP.Distance.Enabled then
                            esp.Distance.Visible = true
                            esp.Distance.Position = Vector2.new(centerX, maxY + 4)
                            esp.Distance.Text = math.floor(target.worldDist).."m"
                            esp.Distance.Color = Config.ESP.Distance.Color
                            esp.Distance.Size = Config.ESP.Distance.Size
                        else esp.Distance.Visible = false end
                        
                        -- Tracer
                        if Config.ESP.Tracer.Enabled then
                            local origin
                            if Config.ESP.Tracer.Origin == "Top" then origin = Vector2.new(Camera.ViewportSize.X/2, 0)
                            elseif Config.ESP.Tracer.Origin == "Center" then origin = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
                            elseif Config.ESP.Tracer.Origin == "Mouse" then origin = GetMousePos()
                            else origin = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y) end
                            esp.Tracer.Visible = true
                            esp.Tracer.From = origin
                            esp.Tracer.To = Vector2.new(centerX, maxY)
                            esp.Tracer.Color = Config.ESP.RainbowMode and GetRainbow(Config.ESP.RainbowSpeed + 0.4) or Config.ESP.Tracer.Color
                            esp.Tracer.Thickness = Config.ESP.Tracer.Thickness
                        else esp.Tracer.Visible = false end
                        
                        -- Chams
                        UpdateChams(plr, char)
                    else
                        -- Offscreen Arrow
                        if Config.ESP.OffscreenArrows.Enabled then
                            local dir = (part.Position - Camera.CFrame.Position).Unit
                            local angle = math.atan2(dir.Z, dir.X)
                            local arrowPos = Vector2.new(Camera.ViewportSize.X/2 + math.cos(angle) * Config.ESP.OffscreenArrows.Radius,
                                                        Camera.ViewportSize.Y/2 + math.sin(angle) * Config.ESP.OffscreenArrows.Radius)
                            esp.OffscreenArrow.Visible = true
                            esp.OffscreenArrow.PointA = arrowPos + Vector2.new(math.cos(angle - 0.5) * Config.ESP.OffscreenArrows.Size, math.sin(angle - 0.5) * Config.ESP.OffscreenArrows.Size)
                            esp.OffscreenArrow.PointB = arrowPos + Vector2.new(math.cos(angle + 0.5) * Config.ESP.OffscreenArrows.Size, math.sin(angle + 0.5) * Config.ESP.OffscreenArrows.Size)
                            esp.OffscreenArrow.PointC = arrowPos + Vector2.new(math.cos(angle) * Config.ESP.OffscreenArrows.Size * 1.8, math.sin(angle) * Config.ESP.OffscreenArrows.Size * 1.8)
                            esp.OffscreenArrow.Color = Config.ESP.RainbowMode and GetRainbow(Config.ESP.RainbowSpeed + 0.6) or Config.ESP.OffscreenArrows.Color
                        else esp.OffscreenArrow.Visible = false end
                        
                        for _, v in pairs({esp.Box.Main, esp.Box.Outline, esp.BoxFill, esp.Name, esp.Distance, esp.Tracer, esp.HealthBar.Outline, esp.HealthBar.Main, esp.HealthBar.Text}) do v.Visible = false end
                        for _, line in pairs(esp.Skeleton) do line.Visible = false end
                    end
                else
                    for _, v in pairs({esp.Box.Main, esp.Box.Outline, esp.BoxFill, esp.Name, esp.Distance, esp.Tracer, esp.HealthBar.Outline, esp.HealthBar.Main, esp.HealthBar.Text, esp.OffscreenArrow}) do v.Visible = false end
                    for _, line in pairs(esp.Skeleton) do line.Visible = false end
                    if esp.Chams then for _, h in pairs(esp.Chams) do h.Enabled = false end end
                end
            else
                RemoveESP(plr)
            end
        end
    else
        for plr, esp in pairs(State.ESPObjects) do RemoveESP(plr) end
    end
    
    -- // HIT MARKERS RENDER // --
    for i = #State.HitMarkers, 1, -1 do
        local m = State.HitMarkers[i]
        if now - m.time > m.duration then
            table.remove(State.HitMarkers, i)
        else
            local alpha = 1 - (now - m.time) / m.duration
            local size = 8 * alpha
            local c = Config.Combat.HitMarker.Color
            local l1 = CreateDrawing("Line", {From = m.pos - Vector2.new(size, size), To = m.pos - Vector2.new(size/2, size/2), Color = c, Thickness = 2, Transparency = alpha, Visible = true})
            local l2 = CreateDrawing("Line", {From = m.pos - Vector2.new(-size, size), To = m.pos - Vector2.new(-size/2, size/2), Color = c, Thickness = 2, Transparency = alpha, Visible = true})
            local l3 = CreateDrawing("Line", {From = m.pos - Vector2.new(size, -size), To = m.pos - Vector2.new(size/2, -size/2), Color = c, Thickness = 2, Transparency = alpha, Visible = true})
            local l4 = CreateDrawing("Line", {From = m.pos - Vector2.new(-size, -size), To = m.pos - Vector2.new(-size/2, -size/2), Color = c, Thickness = 2, Transparency = alpha, Visible = true})
            task.delay(m.duration, function() l1:Remove(); l2:Remove(); l3:Remove(); l4:Remove() end)
        end
    end
    
    -- // ANTI AIM // --
    if Config.Protection.AntiAim.Enabled and hrp then
        local t = Config.Protection.AntiAim.Type
        local speed = Config.Protection.AntiAim.Speed
        if t == "Spin" then
            hrp.CFrame = hrp.CFrame * CFrame.Angles(0, math.rad(speed * dt * 10), 0)
        elseif t == "Jitter" then
            hrp.CFrame = hrp.CFrame * CFrame.Angles(0, math.rad((math.random()-0.5) * speed * 10), 0)
        elseif t == "Backwards" then
            hrp.CFrame = CFrame.new(hrp.Position, hrp.Position - Camera.CFrame.LookVector)
        end
    end
    
    -- // ANTI FLING // --
    if Config.Protection.AntiFling and hrp then
        hrp.Velocity = Vector3.new(Clamp(hrp.Velocity.X, -500, 500), hrp.Velocity.Y, Clamp(hrp.Velocity.Z, -500, 500))
        hrp.RotVelocity = Vector3.new(Clamp(hrp.RotVelocity.X, -50, 50), Clamp(hrp.RotVelocity.Y, -50, 50), Clamp(hrp.RotVelocity.Z, -50, 50))
    end
    
    -- // ANTI VOID // --
    if Config.Protection.AntiVoid and hrp and hrp.Position.Y < -100 then
        hrp.CFrame = CFrame.new(0, 50, 0)
    end
end)

-- // PLAYER EVENTS // --
Players.PlayerAdded:Connect(function(plr)
    plr.CharacterAdded:Connect(function() task.wait(1) CreateESP(plr) end)
    if plr.Character then CreateESP(plr) end
end)

Players.PlayerRemoving:Connect(RemoveESP)

for _, plr in ipairs(Players:GetPlayers()) do
    if plr ~= LocalPlayer then CreateESP(plr) end
end

LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(1)
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then CreateESP(plr) end
    end
end)

-- // HIT DETECTION // --
local function OnHit(char, part)
    if not Config.Combat.HitSound.Enabled and not Config.Combat.HitMarker.Enabled then return end
    local plr = Players:GetPlayerFromCharacter(char)
    if plr and plr ~= LocalPlayer then
        PlayHitSound()
        ShowHitMarker(part.Position)
    end
end

-- // KILL FEED // --
local function OnKill(killer, victim)
    if killer == LocalPlayer then
        if Config.Combat.KillSound.Enabled then
            local s = Instance.new("Sound")
            s.SoundId = Config.Combat.KillSound.SoundId
            s.Volume = Config.Combat.KillSound.Volume
            s.PlayOnRemove = true
            s.Parent = SoundService
            s:Destroy()
        end
        table.insert(State.KillFeed, {victim = victim.Name, time = tick()})
        State.LastKillTime = tick()
    end
end

for _, plr in ipairs(Players:GetPlayers()) do
    if plr ~= LocalPlayer and plr.Character then
        local hum = plr.Character:FindFirstChild("Humanoid")
        if hum then hum.Died:Connect(function() OnKill(LocalPlayer, plr) end) end
    end
end

Players.PlayerAdded:Connect(function(plr)
    plr.CharacterAdded:Connect(function(char)
        local hum = char:WaitForChild("Humanoid")
        hum.Died:Connect(function() OnKill(LocalPlayer, plr) end)
    end)
end)

-- // NEON UI // --
local function CreateUI()
    local sg = Instance.new("ScreenGui")
    sg.Name = "NeonRageUI"
    sg.ResetOnSpawn = false
    sg.IgnoreGuiInset = true
    sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    sg.Parent = CoreGui
    
    local Main = Instance.new("Frame")
    Main.Name = "Main"
    Main.Size = UDim2.new(0, 620, 0, 480)
    Main.Position = UDim2.new(0.5, -310, 0.5, -240)
    Main.BackgroundColor3 = Theme.Background
    Main.BorderSizePixel = 0
    Main.Active = true
    Main.Draggable = true
    Main.Visible = false
    Main.Parent = sg
    
    local MainCorner = Instance.new("UICorner")
    MainCorner.CornerRadius = UDim.new(0, 10)
    MainCorner.Parent = Main
    
    local MainStroke = Instance.new("UIStroke")
    MainStroke.Color = Theme.Border
    MainStroke.Thickness = 1
    MainStroke.Transparency = 0.3
    MainStroke.Parent = Main
    
    local Glow = Instance.new("ImageLabel")
    Glow.Name = "Glow"
    Glow.Size = UDim2.new(1, 40, 1, 40)
    Glow.Position = UDim2.new(0, -20, 0, -20)
    Glow.BackgroundTransparency = 1
    Glow.Image = "rbxassetid://5028857084"
    Glow.ImageColor3 = Theme.Accent
    Glow.ImageTransparency = 0.7
    Glow.ScaleType = Enum.ScaleType.Slice
    Glow.SliceCenter = Rect.new(24, 24, 276, 276)
    Glow.ZIndex = -1
    Glow.Parent = Main
    
    local TitleBar = Instance.new("Frame")
    TitleBar.Size = UDim2.new(1, 0, 0, 40)
    TitleBar.BackgroundColor3 = Theme.Surface
    TitleBar.BorderSizePixel = 0
    TitleBar.Parent = Main
    Instance.new("UICorner", TitleBar).CornerRadius = UDim.new(0, 10)
    
    local TitleGradient = Instance.new("UIGradient")
    TitleGradient.Color = ColorSequence.new{ColorSequenceKeypoint.new(0, Theme.Accent), ColorSequenceKeypoint.new(1, Theme.Purple)}
    TitleGradient.Rotation = 90
    TitleGradient.Parent = TitleBar
    
    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(1, -80, 1, 0)
    Title.Position = UDim2.new(0, 15, 0, 0)
    Title.BackgroundTransparency = 1
    Title.Text = "NEON RAGE"
    Title.TextColor3 = Theme.Text
    Title.TextSize = 18
    Title.Font = Enum.Font.GothamBold
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.Parent = TitleBar
    
    local Subtitle = Instance.new("TextLabel")
    Subtitle.Size = UDim2.new(0, 100, 1, 0)
    Subtitle.Position = UDim2.new(1, -110, 0, 0)
    Subtitle.BackgroundTransparency = 1
    Subtitle.Text = "v2.1.0"
    Subtitle.TextColor3 = Theme.TextDim
    Subtitle.TextSize = 11
    Subtitle.Font = Enum.Font.Gotham
    Subtitle.TextXAlignment = Enum.TextXAlignment.Right
    Subtitle.Parent = TitleBar
    
    local CloseBtn = Instance.new("TextButton")
    CloseBtn.Size = UDim2.new(0, 30, 0, 30)
    CloseBtn.Position = UDim2.new(1, -35, 0, 5)
    CloseBtn.BackgroundColor3 = Theme.Red
    CloseBtn.BackgroundTransparency = 0.8
    CloseBtn.Text = "✕"
    CloseBtn.TextColor3 = Theme.Text
    CloseBtn.TextSize = 14
    CloseBtn.Font = Enum.Font.GothamBold
    CloseBtn.BorderSizePixel = 0
    CloseBtn.Parent = TitleBar
    Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 6)
    CloseBtn.MouseButton1Click:Connect(function() Main.Visible = false end)
    
    local TabBar = Instance.new("Frame")
    TabBar.Size = UDim2.new(0, 140, 1, -45)
    TabBar.Position = UDim2.new(0, 5, 0, 45)
    TabBar.BackgroundColor3 = Theme.Surface
    TabBar.BorderSizePixel = 0
    TabBar.Parent = Main
    Instance.new("UICorner", TabBar).CornerRadius = UDim.new(0, 8)
    
    local TabLayout = Instance.new("UIListLayout")
    TabLayout.Padding = UDim.new(0, 4)
    TabLayout.Parent = TabBar
    
    local Content = Instance.new("Frame")
    Content.Size = UDim2.new(1, -155, 1, -50)
    Content.Position = UDim2.new(0, 150, 0, 45)
    Content.BackgroundTransparency = 1
    Content.Parent = Main
    
    local Tabs = {
        {Name = "Aimbot", Icon = "🎯"},
        {Name = "ESP", Icon = "👁️"},
        {Name = "Movement", Icon = "🏃"},
        {Name = "Combat", Icon = "🔫"},
        {Name = "Visuals", Icon = "👀"},
        {Name = "Protection", Icon = "🛡️"},
        {Name = "Settings", Icon = "⚙️"}
    }
    
    local TabFrames = {}
    local CurrentTab = nil
    
    local function CreateTab(name)
        local frame = Instance.new("ScrollingFrame")
        frame.Name = name
        frame.Size = UDim2.new(1, 0, 1, 0)
        frame.BackgroundTransparency = 1
        frame.BorderSizePixel = 0
        frame.ScrollBarThickness = 4
        frame.ScrollBarImageColor3 = Theme.Accent
        frame.CanvasSize = UDim2.new(0, 0, 0, 0)
        frame.Visible = false
        frame.Parent = Content
        
        local layout = Instance.new("UIListLayout")
        layout.Padding = UDim.new(0, 8)
        layout.Parent = frame
        layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            frame.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 20)
        end)
        
        local padding = Instance.new("UIPadding")
        padding.PaddingTop = UDim.new(0, 10)
        padding.PaddingLeft = UDim.new(0, 10)
        padding.PaddingRight = UDim.new(0, 10)
        padding.Parent = frame
        
        TabFrames[name] = frame
        return frame
    end
    
    for _, tab in ipairs(Tabs) do CreateTab(tab.Name) end
    
    local function SwitchTab(name)
        for n, f in pairs(TabFrames) do f.Visible = (n == name) end
        CurrentTab = name
        for _, btn in pairs(TabBar:GetChildren()) do
            if btn:IsA("TextButton") then
                btn.BackgroundColor3 = btn.Name == name and Theme.Accent or Theme.SurfaceHover
                btn.TextColor3 = btn.Name == name and Theme.Text or Theme.TextDim
            end
        end
    end
    
    for _, tab in ipairs(Tabs) do
        local btn = Instance.new("TextButton")
        btn.Name = tab.Name
        btn.Size = UDim2.new(1, -10, 0, 36)
        btn.BackgroundColor3 = Theme.SurfaceHover
        btn.BorderSizePixel = 0
        btn.Text = "  "..tab.Icon.."  "..tab.Name
        btn.TextColor3 = Theme.TextDim
        btn.TextSize = 13
        btn.Font = Enum.Font.GothamSemibold
        btn.TextXAlignment = Enum.TextXAlignment.Left
        btn.Parent = TabBar
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
        btn.MouseButton1Click:Connect(function() SwitchTab(tab.Name) end)
    end
    
    SwitchTab("Aimbot")
    
    -- // UI BUILDER FUNCTIONS // --
    local function AddSection(parent, title)
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(1, 0, 0, 28)
        frame.BackgroundTransparency = 1
        frame.Parent = parent
        
        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, 0, 1, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text = title
        lbl.TextColor3 = Theme.Accent
        lbl.TextSize = 14
        lbl.Font = Enum.Font.GothamBold
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent = frame
        
        local line = Instance.new("Frame")
        line.Size = UDim2.new(1, 0, 0, 1)
        line.Position = UDim2.new(0, 0, 1, -2)
        line.BackgroundColor3 = Theme.Accent
        line.BackgroundTransparency = 0.5
        line.BorderSizePixel = 0
        line.Parent = frame
        return frame
    end
    
    local function AddToggle(parent, text, configTable, key, ySize)
        ySize = ySize or 32
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, 0, 0, ySize)
        btn.BackgroundColor3 = configTable[key] and Theme.Accent or Theme.SurfaceHover
        btn.BorderSizePixel = 0
        btn.Text = "  "..text.."  ["..(configTable[key] and "ON" or "OFF").."]"
        btn.TextColor3 = Theme.Text
        btn.TextSize = 12
        btn.Font = Enum.Font.GothamSemibold
        btn.TextXAlignment = Enum.TextXAlignment.Left
        btn.Parent = parent
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
        
        local stroke = Instance.new("UIStroke")
        stroke.Color = Theme.Border
        stroke.Thickness = 1
        stroke.Transparency = 0.5
        stroke.Parent = btn
        
        btn.MouseButton1Click:Connect(function()
            configTable[key] = not configTable[key]
            btn.BackgroundColor3 = configTable[key] and Theme.Accent or Theme.SurfaceHover
            btn.Text = "  "..text.."  ["..(configTable[key] and "ON" or "OFF").."]"
            SaveConfig()
        end)
        return btn
    end
    
    local function AddSlider(parent, text, configTable, key, min, max, decimals, suffix)
        suffix = suffix or ""
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(1, 0, 0, 44)
        frame.BackgroundTransparency = 1
        frame.Parent = parent
        
        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, 0, 0, 18)
        lbl.BackgroundTransparency = 1
        lbl.Text = text..": "..string.format("%."..decimals.."f", configTable[key])..suffix
        lbl.TextColor3 = Theme.Text
        lbl.TextSize = 12
        lbl.Font = Enum.Font.Gotham
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent = frame
        
        local bar = Instance.new("Frame")
        bar.Size = UDim2.new(1, 0, 0, 6)
        bar.Position = UDim2.new(0, 0, 0, 22)
        bar.BackgroundColor3 = Theme.Background
        bar.BorderSizePixel = 0
        bar.Parent = frame
        Instance.new("UICorner", bar).CornerRadius = UDim.new(0, 3)
        
        local fill = Instance.new("Frame")
        fill.Size = UDim2.new((configTable[key] - min) / (max - min), 0, 1, 0)
        fill.BackgroundColor3 = Theme.Accent
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
                local rel = Clamp((GetMousePos().X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
                local val = min + (max - min) * rel
                configTable[key] = val
                fill.Size = UDim2.new(rel, 0, 1, 0)
                lbl.Text = text..": "..string.format("%."..decimals.."f", val)..suffix
                SaveConfig()
            end
        end)
        return frame
    end
    
    local function AddDropdown(parent, text, configTable, key, options)
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(1, 0, 0, 32)
        frame.BackgroundColor3 = Theme.Surface
        frame.BorderSizePixel = 0
        frame.Parent = parent
        Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 6)
        
        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(0.4, 0, 1, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text = "  "..text
        lbl.TextColor3 = Theme.Text
        lbl.TextSize = 12
        lbl.Font = Enum.Font.Gotham
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent = frame
        
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0.6, -10, 0, 24)
        btn.Position = UDim2.new(0.4, 5, 0, 4)
        btn.BackgroundColor3 = Theme.Background
        btn.BorderSizePixel = 0
        btn.Text = configTable[key]
        btn.TextColor3 = Theme.Text
        btn.TextSize = 11
        btn.Font = Enum.Font.GothamSemibold
        btn.Parent = frame
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
        
        local open = false
        local list = Instance.new("Frame")
        list.Size = UDim2.new(1, 0, 0, 0)
        list.Position = UDim2.new(0, 0, 1, 2)
        list.BackgroundColor3 = Theme.Surface
        list.BorderSizePixel = 0
        list.Visible = false
        list.ClipsDescendants = true
        list.Parent = btn
        Instance.new("UICorner", list).CornerRadius = UDim.new(0, 4)
        local listLayout = Instance.new("UIListLayout")
        listLayout.Parent = list
        
        for _, opt in ipairs(options) do
            local obtn = Instance.new("TextButton")
            obtn.Size = UDim2.new(1, 0, 0, 24)
            obtn.BackgroundTransparency = 1
            obtn.Text = opt
            obtn.TextColor3 = Theme.Text
            obtn.TextSize = 11
            obtn.Font = Enum.Font.Gotham
            obtn.Parent = list
            obtn.MouseButton1Click:Connect(function()
                configTable[key] = opt
                btn.Text = opt
                list.Visible = false
                open = false
                SaveConfig()
            end)
        end
        
        btn.MouseButton1Click:Connect(function()
            open = not open
            list.Visible = open
            if open then
                list:TweenSize(UDim2.new(1, 0, 0, #options * 24), "Out", "Quad", 0.2, true)
            else
                list:TweenSize(UDim2.new(1, 0, 0, 0), "Out", "Quad", 0.2, true)
            end
        end)
        return frame
    end
    
    local function AddColorPicker(parent, text, configTable, key)
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(1, 0, 0, 32)
        frame.BackgroundTransparency = 1
        frame.Parent = parent
        
        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(0.6, 0, 1, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text = "  "..text
        lbl.TextColor3 = Theme.Text
        lbl.TextSize = 12
        lbl.Font = Enum.Font.Gotham
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent = frame
        
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 50, 0, 24)
        btn.Position = UDim2.new(1, -55, 0, 4)
        btn.BackgroundColor3 = configTable[key]
        btn.BorderSizePixel = 0
        btn.Text = ""
        btn.Parent = frame
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
        
        local presets = {
            Color3.fromRGB(255, 50, 120), Color3.fromRGB(50, 220, 255), Color3.fromRGB(180, 80, 255),
            Color3.fromRGB(255, 200, 50), Color3.fromRGB(60, 220, 120), Color3.fromRGB(255, 100, 50),
            Color3.fromRGB(255, 255, 255), Color3.fromRGB(255, 50, 50), Color3.fromRGB(50, 255, 50)
        }
        local idx = 1
        for i, c in ipairs(presets) do if c == configTable[key] then idx = i break end end
        
        btn.MouseButton1Click:Connect(function()
            idx = idx + 1
            if idx > #presets then idx = 1 end
            configTable[key] = presets[idx]
            btn.BackgroundColor3 = presets[idx]
            SaveConfig()
        end)
        return frame
    end
    
    local function AddKeybind(parent, text, configTable, key)
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(1, 0, 0, 32)
        frame.BackgroundTransparency = 1
        frame.Parent = parent
        
        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(0.6, 0, 1, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text = "  "..text
        lbl.TextColor3 = Theme.Text
        lbl.TextSize = 12
        lbl.Font = Enum.Font.Gotham
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent = frame
        
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 120, 0, 24)
        btn.Position = UDim2.new(1, -125, 0, 4)
        btn.BackgroundColor3 = Theme.Background
        btn.BorderSizePixel = 0
        btn.Text = tostring(configTable[key]):gsub("Enum%.%w+%.", "")
        btn.TextColor3 = Theme.Text
        btn.TextSize = 11
        btn.Font = Enum.Font.GothamSemibold
        btn.Parent = frame
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
        
        local listening = false
        btn.MouseButton1Click:Connect(function()
            listening = true
            btn.Text = "..."
            btn.TextColor3 = Theme.Accent
        end)
        
        UserInputService.InputBegan:Connect(function(input, gp)
            if listening and not gp then
                if input.UserInputType == Enum.UserInputType.Keyboard or input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.MouseButton2 then
                    configTable[key] = input.KeyCode ~= Enum.KeyCode.Unknown and input.KeyCode or input.UserInputType
                    btn.Text = tostring(configTable[key]):gsub("Enum%.%w+%.", "")
                    btn.TextColor3 = Theme.Text
                    listening = false
                    SaveConfig()
                end
            end
        end)
        return frame
    end
    
    local function AddButton(parent, text, callback, color)
        color = color or Theme.Accent
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, 0, 0, 32)
        btn.BackgroundColor3 = color
        btn.BorderSizePixel = 0
        btn.Text = text
        btn.TextColor3 = Theme.Text
        btn.TextSize = 12
        btn.Font = Enum.Font.GothamBold
        btn.Parent = parent
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
        btn.MouseButton1Click:Connect(callback)
        return btn
    end
    
    -- // BUILD TABS // --
    -- AIMBOT TAB
    do
        local tab = TabFrames.Aimbot
        AddSection(tab, "MAIN")
        AddToggle(tab, "Enabled", Config.Aimbot, "Enabled")
        AddToggle(tab, "Silent Aim", Config.Aimbot, "SilentAim")
        AddToggle(tab, "Camera Aim", Config.Aimbot, "CameraAim")
        AddToggle(tab, "Triggerbot", Config.Aimbot, "Triggerbot")
        
        AddSection(tab, "TARGETING")
        AddDropdown(tab, "Target Part", Config.Aimbot, "TargetPart", {"Head", "UpperTorso", "LowerTorso", "HumanoidRootPart", "Random"})
        AddDropdown(tab, "Priority", Config.Aimbot, "Priority", {"Crosshair", "Distance", "Health"})
        AddToggle(tab, "Team Check", Config.Aimbot, "TeamCheck")
        AddToggle(tab, "Wall Check", Config.Aimbot, "WallCheck")
        AddToggle(tab, "Alive Check", Config.Aimbot, "AliveCheck")
        AddSlider(tab, "Max Distance", Config.Aimbot, "MaxDist", 100, 5000, 0, "m")
        AddSlider(tab, "Hit Chance %", Config.Aimbot, "HitChance", 0, 100, 0, "%")
        
        AddSection(tab, "PREDICTION")
        AddToggle(tab, "Enabled", Config.Aimbot, "Prediction")
        AddToggle(tab, "Velocity Prediction", Config.Aimbot, "PredVelocity")
        AddToggle(tab, "Gravity Prediction", Config.Aimbot, "PredGravity")
        AddSlider(tab, "Projectile Speed", Config.Aimbot, "ProjectileSpeed", 100, 100000, 0, " studs/s")
        
        AddSection(tab, "SMOOTHING & HUMANIZER")
        AddSlider(tab, "Smoothness", Config.Aimbot, "Smoothness", 0.005, 0.2, 3)
        AddToggle(tab, "Humanize", Config.Aimbot, "Humanize")
        AddSlider(tab, "Reaction Delay", Config.Aimbot, "ReactionDelay", 0, 0.3, 3, "s")
        AddSlider(tab, "Overshoot Correction", Config.Aimbot, "OvershootCorr", 0, 0.5, 2)
        AddToggle(tab, "Micro Jitter", Config.Aimbot.Jitter, "Enabled")
        AddSlider(tab, "Jitter Intensity", Config.Aimbot.Jitter, "Intensity", 0, 2, 2)
        AddSlider(tab, "Jitter Frequency", Config.Aimbot.Jitter, "Freq", 0.02, 0.2, 3, "s")
        
        AddSection(tab, "FOV SETTINGS")
        AddToggle(tab, "Show FOV Circle", Config.Aimbot, "ShowFOV")
        AddSlider(tab, "FOV Radius", Config.Aimbot, "FOV", 20, 500, 0, "px")
        AddColorPicker(tab, "FOV Color", Config.Aimbot, "FOVColor")
        
        AddSection(tab, "KEYBINDS")
        AddKeybind(tab, "Aim Key", Config.Aimbot, "AimKey")
        AddToggle(tab, "Toggle Mode", Config.Aimbot, "ToggleMode")
    end
    
    -- ESP TAB
    do
        local tab = TabFrames.ESP
        AddSection(tab, "MASTER")
        AddToggle(tab, "Enabled", Config.ESP, "Enabled")
        AddToggle(tab, "Team Check", Config.ESP, "TeamCheck")
        AddSlider(tab, "Max Distance", Config.ESP, "MaxDist", 500, 10000, 0, "m")
        AddToggle(tab, "Rainbow Mode", Config.ESP, "RainbowMode")
        AddSlider(tab, "Rainbow Speed", Config.ESP, "RainbowSpeed", 0.5, 5, 1)
        
        AddSection(tab, "BOX ESP")
        AddToggle(tab, "Enabled", Config.ESP.Box, "Enabled")
        AddDropdown(tab, "Type", Config.ESP.Box, "Type", {"Corner", "Full", "3D"})
        AddColorPicker(tab, "Color", Config.ESP.Box, "Color")
        AddSlider(tab, "Thickness", Config.ESP.Box, "Thickness", 0.5, 5, 1)
        AddToggle(tab, "Filled", Config.ESP.Box, "Filled")
        AddSlider(tab, "Fill Transparency", Config.ESP.Box, "FillTransparency", 0, 1, 2)
        
        AddSection(tab, "SKELETON")
        AddToggle(tab, "Enabled", Config.ESP.Skeleton, "Enabled")
        AddColorPicker(tab, "Color", Config.ESP.Skeleton, "Color")
        AddSlider(tab, "Thickness", Config.ESP.Skeleton, "Thickness", 0.5, 5, 1)
        
        AddSection(tab, "HEALTH BAR")
        AddToggle(tab, "Enabled", Config.ESP.HealthBar, "Enabled")
        AddDropdown(tab, "Side", Config.ESP.HealthBar, "Side", {"Left", "Right"})
        AddToggle(tab, "Show Text", Config.ESP.HealthBar, "ShowText")
        
        AddSection(tab, "NAME & DISTANCE")
        AddToggle(tab, "Name Enabled", Config.ESP.Name, "Enabled")
        AddColorPicker(tab, "Name Color", Config.ESP.Name, "Color")
        AddSlider(tab, "Name Size", Config.ESP.Name, "Size", 10, 20, 0)
        AddToggle(tab, "Distance Enabled", Config.ESP.Distance, "Enabled")
        AddColorPicker(tab, "Distance Color", Config.ESP.Distance, "Color")
        
        AddSection(tab, "TRACERS")
        AddToggle(tab, "Enabled", Config.ESP.Tracer, "Enabled")
        AddDropdown(tab, "Origin", Config.ESP.Tracer, "Origin", {"Top", "Center", "Bottom", "Mouse"})
        AddColorPicker(tab, "Color", Config.ESP.Tracer, "Color")
        AddSlider(tab, "Thickness", Config.ESP.Tracer, "Thickness", 0.5, 3, 1)
        
        AddSection(tab, "CHAMS (HIGHLIGHT)")
        AddToggle(tab, "Enabled", Config.ESP.Chams, "Enabled")
        AddColorPicker(tab, "Fill Color", Config.ESP.Chams, "FillColor")
        AddColorPicker(tab, "Outline Color", Config.ESP.Chams, "OutlineColor")
        AddSlider(tab, "Fill Transparency", Config.ESP.Chams, "FillTrans", 0, 1, 2)
        AddSlider(tab, "Outline Transparency", Config.ESP.Chams, "OutlineTrans", 0, 1, 2)
        
        AddSection(tab, "OFFSCREEN ARROWS")
        AddToggle(tab, "Enabled", Config.ESP.OffscreenArrows, "Enabled")
        AddSlider(tab, "Size", Config.ESP.OffscreenArrows, "Size", 10, 50, 0)
        AddColorPicker(tab, "Color", Config.ESP.OffscreenArrows, "Color")
        AddSlider(tab, "Radius", Config.ESP.OffscreenArrows, "Radius", 100, 500, 0)
    end
    
    -- MOVEMENT TAB
    do
        local tab = TabFrames.Movement
        AddSection(tab, "SPEED HACK")
        AddToggle(tab, "Enabled", Config.Movement.SpeedHack, "Enabled")
        AddDropdown(tab, "Method", Config.Movement.SpeedHack, "Method", {"CFrame", "Velocity", "BodyVelocity"})
        AddSlider(tab, "Speed", Config.Movement.SpeedHack, "Speed", 16, 100, 0, " studs/s")
        
        AddSection(tab, "FLY")
        AddToggle(tab, "Enabled", Config.Movement.Fly, "Enabled")
        AddSlider(tab, "Speed", Config.Movement.Fly, "Speed", 10, 200, 0)
        AddKeybind(tab, "Toggle Key", Config.Movement.Fly, "Keybind")
        
        AddSection(tab, "NOCLIP")
        AddToggle(tab, "Enabled", Config.Movement.NoClip, "Enabled")
        AddKeybind(tab, "Toggle Key", Config.Movement.NoClip, "Keybind")
        
        AddSection(tab, "OTHER")
        AddToggle(tab, "Infinite Jump", Config.Movement.InfiniteJump, "Enabled")
        AddToggle(tab, "Bunny Hop", Config.Movement.Bhop, "Enabled")
        AddSlider(tab, "Bhop Height", Config.Movement.Bhop, "Height", 5, 20, 1)
        AddToggle(tab, "Air Walk", Config.Movement.AirWalk, "Enabled")
        AddKeybind(tab, "Air Walk Key", Config.Movement.AirWalk, "Keybind")
        AddToggle(tab, "Swim Fly", Config.Movement.SwimFly, "Enabled")
        AddToggle(tab, "Auto Parry", Config.Movement.AutoParry, "Enabled")
        AddSlider(tab, "Parry Range", Config.Movement.AutoParry, "Range", 10, 50, 0)
    end
    
    -- COMBAT TAB
    do
        local tab = TabFrames.Combat
        AddSection(tab, "GUN MODS")
        AddToggle(tab, "Rapid Fire", Config.Combat, "RapidFire")
        AddToggle(tab, "No Recoil", Config.Combat, "NoRecoil")
        AddToggle(tab, "No Spread", Config.Combat, "NoSpread")
        AddToggle(tab, "Infinite Ammo", Config.Combat, "InfiniteAmmo")
        AddToggle(tab, "Auto Reload", Config.Combat, "AutoReload")
        
        AddSection(tab, "HIT FEEDBACK")
        AddToggle(tab, "Hit Sound", Config.Combat.HitSound, "Enabled")
        AddSlider(tab, "Hit Sound Volume", Config.Combat.HitSound, "Volume", 0, 5, 1)
        AddToggle(tab, "Hit Marker", Config.Combat.HitMarker, "Enabled")
        AddColorPicker(tab, "Hit Marker Color", Config.Combat.HitMarker, "Color")
        AddSlider(tab, "Hit Marker Time", Config.Combat.HitMarker, "Time", 0.1, 1, 2, "s")
        AddToggle(tab, "Kill Sound", Config.Combat.KillSound, "Enabled")
        AddSlider(tab, "Kill Sound Volume", Config.Combat.KillSound, "Volume", 0, 5, 1)
    end
    
    -- VISUALS TAB
    do
        local tab = TabFrames.Visuals
        AddSection(tab, "CROSSHAIR")
        AddToggle(tab, "Enabled", Config.Visuals.Crosshair, "Enabled")
        AddDropdown(tab, "Type", Config.Visuals.Crosshair, "Type", {"Dot", "Cross", "Circle", "Dynamic"})
        AddSlider(tab, "Size", Config.Visuals.Crosshair, "Size", 2, 30, 0)
        AddSlider(tab, "Gap", Config.Visuals.Crosshair, "Gap", 0, 20, 0)
        AddSlider(tab, "Thickness", Config.Visuals.Crosshair, "Thickness", 0.5, 5, 1)
        AddColorPicker(tab, "Color", Config.Visuals.Crosshair, "Color")
        AddToggle(tab, "Rainbow", Config.Visuals.Crosshair, "Rainbow")
        AddSlider(tab, "Rotation Speed", Config.Visuals.Crosshair, "RotationSpeed", 0, 10, 1)
        
        AddSection(tab, "WORLD")
        AddToggle(tab, "Rainbow Gun", Config.Visuals, "RainbowGun")
        AddToggle(tab, "Full Bright", Config.Visuals, "FullBright")
        AddToggle(tab, "No Fog", Config.Visuals, "NoFog")
        AddColorPicker(tab, "Ambient Light", Config.Visuals, "Ambient")
        
        AddSection(tab, "CAMERA")
        AddToggle(tab, "FOV Changer", Config.Visuals.FOVChanger, "Enabled")
        AddSlider(tab, "FOV Value", Config.Visuals.FOVChanger, "Value", 30, 120, 0)
        AddToggle(tab, "Remove Camera Shake", Config.Visuals, "RemoveCamShake")
    end
    
    -- PROTECTION TAB
    do
        local tab = TabFrames.Protection
        AddSection(tab, "ANTI AIM")
        AddToggle(tab, "Enabled", Config.Protection.AntiAim, "Enabled")
        AddDropdown(tab, "Type", Config.Protection.AntiAim, "Type", {"Spin", "Jitter", "Backwards", "Random"})
        AddSlider(tab, "Speed", Config.Protection.AntiAim, "Speed", 1, 100, 0)
        
        AddSection(tab, "PROTECTIONS")
        AddToggle(tab, "Anti Fling", Config.Protection, "AntiFling")
        AddToggle(tab, "Anti Void", Config.Protection, "AntiVoid")
        AddToggle(tab, "Auto Respawn", Config.Protection, "AutoRespawn")
        AddToggle(tab, "Chat Spy", Config.Protection, "ChatSpy")
        AddToggle(tab, "Anti AFK", Config.Protection, "AntiAFK")
    end
    
    -- SETTINGS TAB
    do
        local tab = TabFrames.Settings
        AddSection(tab, "UI SETTINGS")
        AddColorPicker(tab, "Accent Color", Config.UI, "AccentColor")
        AddKeybind(tab, "Menu Keybind", Config.UI, "Keybind")
        AddToggle(tab, "Watermark", Config.UI, "Watermark")
        AddToggle(tab, "Keybinds List", Config.UI, "KeybindsList")
        AddToggle(tab, "Spectator List", Config.UI, "SpectatorList")
        
        AddSection(tab, "CONFIG")
        AddButton(tab, "Save Config", function() SaveConfig() print("[NEON] Config saved!") end, Theme.Green)
        AddButton(tab, "Load Config", function() LoadConfig() print("[NEON] Config loaded!") end, Theme.Cyan)
        AddButton(tab, "Reset Config", function() 
            if isfile(CONFIG_FILE) then delfile(CONFIG_FILE) end
            print("[NEON] Config reset!")
        end, Theme.Yellow)
        AddButton(tab, "Unload Cheat", function() getgenv().NeonRageUnload() end, Theme.Red)
        
        AddSection(tab, "INFO")
        local info = Instance.new("TextLabel")
        info.Size = UDim2.new(1, 0, 0, 80)
        info.BackgroundTransparency = 1
        info.Text = "NEON RAGE v2.1.0 (FIXED)\nFixed: HealthBar spam, Font Enum, RenderStepped leaks.\nMade for educational purposes. Use at your own risk.\nINSERT to toggle menu."
        info.TextColor3 = Theme.TextDim
        info.TextSize = 11
        info.Font = Enum.Font.Gotham
        info.TextXAlignment = Enum.TextXAlignment.Left
        info.TextYAlignment = Enum.TextYAlignment.Top
        info.Parent = tab
    end
    
    -- // WATERMARK // --
    local Watermark = Instance.new("Frame")
    Watermark.Name = "Watermark"
    Watermark.Size = UDim2.new(0, 220, 0, 30)
    Watermark.Position = UDim2.new(1, -230, 0, 10)
    Watermark.BackgroundColor3 = Theme.Background
    Watermark.BorderSizePixel = 0
    Watermark.Visible = Config.UI.Watermark
    Watermark.Parent = sg
    Instance.new("UICorner", Watermark).CornerRadius = UDim.new(0, 6)
    local wStroke = Instance.new("UIStroke")
    wStroke.Color = Theme.Accent
    wStroke.Thickness = 1
    wStroke.Transparency = 0.3
    wStroke.Parent = Watermark
    
    local wText = Instance.new("TextLabel")
    wText.Size = UDim2.new(1, -20, 1, 0)
    wText.Position = UDim2.new(0, 10, 0, 0)
    wText.BackgroundTransparency = 1
    wText.Text = "NEON RAGE | "..LocalPlayer.Name.." | 0 FPS | 0ms"
    wText.TextColor3 = Theme.Text
    wText.TextSize = 12
    wText.Font = Enum.Font.GothamSemibold
    wText.TextXAlignment = Enum.TextXAlignment.Left
    wText.Parent = Watermark
    
    local wAccent = Instance.new("Frame")
    wAccent.Size = UDim2.new(0, 3, 1, -4)
    wAccent.Position = UDim2.new(0, 2, 0, 2)
    wAccent.BackgroundColor3 = Theme.Accent
    wAccent.BorderSizePixel = 0
    wAccent.Parent = Watermark
    Instance.new("UICorner", wAccent).CornerRadius = UDim.new(0, 2)
    
    -- // KEYBINDS LIST // --
    local KeybindsFrame = Instance.new("Frame")
    KeybindsFrame.Name = "KeybindsList"
    KeybindsFrame.Size = UDim2.new(0, 200, 0, 100)
    KeybindsFrame.Position = UDim2.new(1, -210, 1, -110)
    KeybindsFrame.BackgroundColor3 = Theme.Background
    KeybindsFrame.BorderSizePixel = 0
    KeybindsFrame.Visible = Config.UI.KeybindsList
    KeybindsFrame.Parent = sg
    Instance.new("UICorner", KeybindsFrame).CornerRadius = UDim.new(0, 6)
    local kbStroke = Instance.new("UIStroke")
    kbStroke.Color = Theme.Border
    kbStroke.Thickness = 1
    kbStroke.Transparency = 0.3
    kbStroke.Parent = KeybindsFrame
    
    local kbTitle = Instance.new("TextLabel")
    kbTitle.Size = UDim2.new(1, 0, 0, 24)
    kbTitle.BackgroundTransparency = 1
    kbTitle.Text = "  KEYBINDS"
    kbTitle.TextColor3 = Theme.Accent
    kbTitle.TextSize = 12
    kbTitle.Font = Enum.Font.GothamBold
    kbTitle.TextXAlignment = Enum.TextXAlignment.Left
    kbTitle.Parent = KeybindsFrame
    
    local kbLayout = Instance.new("UIListLayout")
    kbLayout.Padding = UDim.new(0, 2)
    kbLayout.Parent = KeybindsFrame
    
    local function UpdateKeybindsList()
        for _, child in pairs(KeybindsFrame:GetChildren()) do
            if child:IsA("TextLabel") and child ~= kbTitle then child:Destroy() end
        end
        local binds = {
            {"Aim", Config.Aimbot.AimKey},
            {"Fly", Config.Movement.Fly.Keybind},
            {"NoClip", Config.Movement.NoClip.Keybind},
            {"AirWalk", Config.Movement.AirWalk.Keybind},
            {"Triggerbot", Config.Aimbot.TriggerKey},
            {"Menu", Config.UI.Keybind}
        }
        for _, b in ipairs(binds) do
            local lbl = Instance.new("TextLabel")
            lbl.Size = UDim2.new(1, -20, 0, 18)
            lbl.BackgroundTransparency = 1
            lbl.Text = "  "..b[1]..": "..tostring(b[2]):gsub("Enum%.%w+%.", "")
            lbl.TextColor3 = Theme.Text
            lbl.TextSize = 11
            lbl.Font = Enum.Font.Gotham
            lbl.TextXAlignment = Enum.TextXAlignment.Left
            lbl.Parent = KeybindsFrame
        end
        KeybindsFrame.Size = UDim2.new(0, 200, 0, 30 + #binds * 20)
    end
    UpdateKeybindsList()
    
    -- // SPECTATOR LIST // --
    local SpecFrame = Instance.new("Frame")
    SpecFrame.Name = "SpectatorList"
    SpecFrame.Size = UDim2.new(0, 200, 0, 30)
    SpecFrame.Position = UDim2.new(0, 10, 1, -110)
    SpecFrame.BackgroundColor3 = Theme.Background
    SpecFrame.BorderSizePixel = 0
    SpecFrame.Visible = Config.UI.SpectatorList
    SpecFrame.Parent = sg
    Instance.new("UICorner", SpecFrame).CornerRadius = UDim.new(0, 6)
    local sStroke = Instance.new("UIStroke")
    sStroke.Color = Theme.Border
    sStroke.Thickness = 1
    sStroke.Transparency = 0.3
    sStroke.Parent = SpecFrame
    
    local sTitle = Instance.new("TextLabel")
    sTitle.Size = UDim2.new(1, 0, 0, 24)
    sTitle.BackgroundTransparency = 1
    sTitle.Text = "  SPECTATORS"
    sTitle.TextColor3 = Theme.Accent
    sTitle.TextSize = 12
    sTitle.Font = Enum.Font.GothamBold
    sTitle.TextXAlignment = Enum.TextXAlignment.Left
    sTitle.Parent = SpecFrame
    
    local sLayout = Instance.new("UIListLayout")
    sLayout.Padding = UDim.new(0, 2)
    sLayout.Parent = SpecFrame
    
    -- // CROSSHAIR RENDERING (GUI) // --
    local CrosshairGui = Instance.new("ScreenGui")
    CrosshairGui.Name = "NeonCrosshair"
    CrosshairGui.ResetOnSpawn = false
    CrosshairGui.IgnoreGuiInset = true
    CrosshairGui.Parent = CoreGui
    
    local function CreateCrosshair()
        for _, p in pairs(State.CrosshairParts) do p:Destroy() end
        State.CrosshairParts = {}
        if State.DynamicCrosshairConn then State.DynamicCrosshairConn:Disconnect() end
        
        local c = Config.Visuals.Crosshair
        if not c.Enabled then CrosshairGui.Enabled = false return end
        CrosshairGui.Enabled = true
        
        local color = c.Rainbow and GetRainbow(c.RotationSpeed) or c.Color
        
        if c.Type == "Dot" then
            local dot = Instance.new("Frame")
            dot.Size = UDim2.new(0, c.Size, 0, c.Size)
            dot.Position = UDim2.new(0.5, -c.Size/2, 0.5, -c.Size/2)
            dot.BackgroundColor3 = color
            dot.BorderSizePixel = 0
            dot.Parent = CrosshairGui
            Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)
            table.insert(State.CrosshairParts, dot)
        elseif c.Type == "Cross" then
            local h = Instance.new("Frame")
            h.Size = UDim2.new(0, c.Size*2 + c.Gap*2, 0, c.Thickness)
            h.Position = UDim2.new(0.5, -c.Size - c.Gap, 0.5, -c.Thickness/2)
            h.BackgroundColor3 = color
            h.BorderSizePixel = 0
            h.Parent = CrosshairGui
            table.insert(State.CrosshairParts, h)
            
            local v = Instance.new("Frame")
            v.Size = UDim2.new(0, c.Thickness, 0, c.Size*2 + c.Gap*2)
            v.Position = UDim2.new(0.5, -c.Thickness/2, 0.5, -c.Size - c.Gap)
            v.BackgroundColor3 = color
            v.BorderSizePixel = 0
            v.Parent = CrosshairGui
            table.insert(State.CrosshairParts, v)
        elseif c.Type == "Circle" then
            local circle = Instance.new("Frame")
            circle.Size = UDim2.new(0, c.Size*2, 0, c.Size*2)
            circle.Position = UDim2.new(0.5, -c.Size, 0.5, -c.Size)
            circle.BackgroundTransparency = 1
            circle.BorderSizePixel = 0
            circle.Parent = CrosshairGui
            local stroke = Instance.new("UIStroke")
            stroke.Color = color
            stroke.Thickness = c.Thickness
            stroke.Parent = circle
            Instance.new("UICorner", circle).CornerRadius = UDim.new(1, 0)
            table.insert(State.CrosshairParts, circle)
        elseif c.Type == "Dynamic" then
            local spread = 0
            for i = 1, 4 do
                local line = Instance.new("Frame")
                line.Size = UDim2.new(0, c.Size, 0, c.Thickness)
                line.BackgroundColor3 = color
                line.BorderSizePixel = 0
                line.Parent = CrosshairGui
                table.insert(State.CrosshairParts, line)
            end
            State.DynamicCrosshairConn = RunService.RenderStepped:Connect(function()
                if not Config.Visuals.Crosshair.Enabled or Config.Visuals.Crosshair.Type ~= "Dynamic" then return end
                local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
                local moving = hum and hum.MoveDirection.Magnitude > 0
                spread = Lerp(spread, moving and c.Size*2 or c.Size, 0.1)
                local center = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
                local offsets = {
                    Vector2.new(-spread - c.Gap, 0), -- Left
                    Vector2.new(c.Gap, 0),           -- Right
                    Vector2.new(0, -spread - c.Gap), -- Up
                    Vector2.new(0, c.Gap)            -- Down
                }
                for i, p in pairs(State.CrosshairParts) do
                    p.Size = UDim2.new(0, spread, 0, c.Thickness)
                    p.Position = UDim2.new(0.5, offsets[i].X - (i<=2 and spread/2 or c.Thickness/2), 0.5, offsets[i].Y - (i>2 and spread/2 or c.Thickness/2))
                    p.Rotation = (i > 2) and 90 or 0
                    if c.Rainbow then p.BackgroundColor3 = GetRainbow(c.RotationSpeed) end
                end
            end)
        end
    end
    
    -- // ANIMATIONS // --
    State.Connections.GlowAnim = RunService.RenderStepped:Connect(function()
        if Glow and Glow.Parent then
            Glow.ImageColor3 = Theme.Accent
            Glow.ImageTransparency = 0.6 + math.sin(tick()*2)*0.1
        end
    end)
    
    -- // INPUT HANDLING // --
    State.Connections.MenuToggle = UserInputService.InputBegan:Connect(function(input, gp)
        if gp then return end
        if input.KeyCode == Config.UI.Keybind then
            Main.Visible = not Main.Visible
            if Main.Visible then
                Main.Size = UDim2.new(0, 0, 0, 0)
                Main:TweenSize(UDim2.new(0, 620, 0, 480), "Out", "Quad", 0.3, true)
            end
        end
    end)
    
    -- // UI RENDER STEP (Watermark, Keybinds, Crosshair Rainbow) // --
    State.Connections.UIRender = RunService.RenderStepped:Connect(function()
        -- Watermark FPS/Ping
        if Config.UI.Watermark and Watermark.Visible then
            local fps = math.floor(1 / RunService.RenderStepped:Wait()) -- Wait() ici est safe car c'est la seule connexion UI RenderStepped
            local ping = math.floor(LocalPlayer:GetNetworkPing()*1000)
            wText.Text = "NEON RAGE | "..LocalPlayer.Name.." | "..fps.." FPS | "..ping.."ms"
            wAccent.BackgroundColor3 = Theme.Accent
        end
        Watermark.Visible = Config.UI.Watermark
        KeybindsFrame.Visible = Config.UI.KeybindsList
        SpecFrame.Visible = Config.UI.SpectatorList
        
        -- Crosshair Rainbow Update
        if Config.Visuals.Crosshair.Enabled and Config.Visuals.Crosshair.Rainbow and Config.Visuals.Crosshair.Type ~= "Dynamic" then
            local color = GetRainbow(Config.Visuals.Crosshair.RotationSpeed)
            for _, p in pairs(State.CrosshairParts) do
                if p:IsA("Frame") then p.BackgroundColor3 = color
                elseif p:FindFirstChild("UIStroke") then p.UIStroke.Color = color end
            end
        end
        
        -- Rainbow Gun
        if Config.Visuals.RainbowGun then
            local tool = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Tool")
            if tool then
                for _, part in pairs(tool:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.Color = GetRainbow(1)
                    end
                end
            end
        end
    end)
    
    CreateCrosshair()
    
    -- // UNLOAD FUNCTION // --
    getgenv().NeonRageUnload = function()
        Config.Aimbot.Enabled = false
        Config.ESP.Enabled = false
        Config.Visuals.Crosshair.Enabled = false
        
        for _, conn in pairs(State.Connections) do conn:Disconnect() end
        for _, d in pairs(State.Drawings) do if d.Remove then d:Remove() end end
        for plr, _ in pairs(State.ESPObjects) do RemoveESP(plr) end
        
        if State.FlyBodyVel then State.FlyBodyVel:Destroy() end
        if State.FlyBodyGyro then State.FlyBodyGyro:Destroy() end
        if State.AirWalkPart then State.AirWalkPart:Destroy() end
        if State.DynamicCrosshairConn then State.DynamicCrosshairConn:Disconnect() end
        
        if oldNamecall then hookmetamethod(game, "__namecall", oldNamecall) end
        
        if sg then sg:Destroy() end
        if CrosshairGui then CrosshairGui:Destroy() end
        if Watermark then Watermark:Destroy() end
        if KeybindsFrame then KeybindsFrame:Destroy() end
        if SpecFrame then SpecFrame:Destroy() end
        
        getgenv().NeonRageLoaded = false
        print("[NEON] Fully unloaded.")
    end
    
    LoadConfig()
    
    print("[NEON] Loaded successfully! INSERT to open menu.")
    print("[NEON] Features: Aimbot, ESP, Movement, Combat, Visuals, Protection")
end

CreateUI()

-- // CHAT SPY // --
if Config.Protection.ChatSpy then
    local function OnChatted(plr, msg)
        if plr ~= LocalPlayer then
            print("[CHAT] "..plr.Name..": "..msg)
            StarterGui:SetCore("ChatMakeSystemMessage", {
                Text = "[SPY] "..plr.Name..": "..msg,
                Color = Color3.fromRGB(255, 100, 100),
                Font = Enum.Font.Gotham,
                TextSize = 14
            })
        end
    end
    for _, plr in ipairs(Players:GetPlayers()) do
        plr.Chatted:Connect(function(msg) OnChatted(plr, msg) end)
    end
    Players.PlayerAdded:Connect(function(plr)
        plr.Chatted:Connect(function(msg) OnChatted(plr, msg) end)
    end)
end

-- // AUTO RESPAWN // --
if Config.Protection.AutoRespawn then
    LocalPlayer.CharacterAdded:Connect(function(char)
        char:WaitForChild("Humanoid").Died:Connect(function()
            task.wait(0.5)
            LocalPlayer:LoadCharacter()
        end)
    end)
end
