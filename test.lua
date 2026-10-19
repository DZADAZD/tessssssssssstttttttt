--[[
    ZYROSCRIPT v4.0 — Anime Dice Trade Freeze (STABLE / NO FREEZE SPAM / UI FIXED)
    RightShift = Ouvrir/Fermer | Drag Header = Deplacer
    Freeze LOOP RETIRE (c'etait lui qui cassait les trades)
]]--

-- ===== POLYFILLS =====
local function str_trim(s) return s:match("^%s*(.-)%s*$") end
local function serialize(t)
    if type(t) ~= "table" then return tostring(t) end
    local out = {}
    for i, v in ipairs(t) do
        if type(v) == "table" then out[i] = "<table>"
        elseif typeof(v) == "Instance" then out[i] = v:GetFullName()
        else out[i] = tostring(v) end
    end
    return "{ " .. table.concat(out, ", ") .. " }"
end
local function log(msg) print("[" .. os.date("%H:%M:%S") .. "] ZYRO :: " .. msg) end

-- ===== SERVICES =====
local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")
local TweenService      = game:GetService("TweenService")
local UserInputService  = game:GetService("UserInputService")
local LocalPlayer       = Players.LocalPlayer

-- ===== CONFIG (A REMPLIR APRES DUMP) =====
local CONFIG = {
    acceptRemote   = "TradeAccept",   -- RemoteEvent/Function : accepter le trade
    addRemote      = "TradeAddItem",  -- RemoteEvent : ajouter un item
    -- setListRemote RETIRE (etait la source du spam)
    acceptArgs   = "AUTO",
    addArgs      = "AUTO",
}

-- ===== CAPTURE REMOTES (__namecall) =====
local allRemotes = {}
local capturedArgs = {}
local incomingArgs = {}

local function scanRemotes()
    allRemotes = {}
    local function add(obj)
        if (obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction")) then
            table.insert(allRemotes, obj)
            if obj:IsA("RemoteEvent") then
                pcall(function()
                    obj.OnClientEvent:Connect(function(...) incomingArgs[obj.Name] = {...} end)
                end)
            end
        end
    end
    pcall(function() for _, o in ipairs(ReplicatedStorage:GetDescendants()) do add(o) end end)
    pcall(function() for _, o in ipairs(workspace:GetDescendants()) do add(o) end end)
end

local function getRemote(name)
    for _, r in ipairs(allRemotes) do if r.Name == name then return r end end
    return nil
end

local hookActive = false
local function enableNamecallHook()
    if hookActive then return end
    local mt = getrawmetatable(game)
    if not mt then log("WARN: getrawmetatable missing"); return end
    local oldNamecall = mt.__namecall
    local setreadonly = make_writeable or setreadonly
    if not setreadonly then log("WARN: setreadonly missing"); return end

    local ok = pcall(function()
        setreadonly(mt, false)
        mt.__namecall = newcclosure(function(self, ...)
            local method = getnamecallmethod()
            local args = {...}
            if (method == "FireServer" or method == "InvokeServer") and (self:IsA("RemoteEvent") or self:IsA("RemoteFunction")) then
                capturedArgs[self.Name] = args
                log("CAPTURED '" .. self.Name .. "' (" .. method .. ") : " .. serialize(args))
            end
            return oldNamecall(self, ...)
        end)
        setreadonly(mt, true)
        hookActive = true
        log("HOOK __namecall ACTIVE")
    end)
    if not ok then log("HOOK FAILED - using CONFIG fallback") end
end

-- ===== ACTIONS (SINGLE FIRE, PAS DE BOUCLE) =====
local targetPlayer = nil

local function getArgs(key)
    local v = CONFIG[key]
    if v == "AUTO" then
        local name = key == "acceptArgs" and CONFIG.acceptRemote
                   or key == "addArgs"    and CONFIG.addRemote
        return capturedArgs[name] or incomingArgs[name] or {}
    end
    return v
end

local function doForceAccept()
    local r = getRemote(CONFIG.acceptRemote)
    if not r then log("ERR: Accept remote missing -> click Dump Remotes"); return end
    local args = getArgs("acceptArgs")
    if #args == 0 then log("WARN: Accept args empty - do manual accept once first"); return end
    log("FORCE ACCEPT -> fire " .. r.Name)
    if r:IsA("RemoteEvent") then pcall(function() r:FireServer(unpack(args)) end)
    else pcall(function() r:InvokeServer(unpack(args)) end) end
end

local function doAutoAdd()
    local r = getRemote(CONFIG.addRemote)
    if not r then log("ERR: Add remote missing -> click Dump Remotes"); return end
    local args = getArgs("addArgs")
    if #args == 0 then log("WARN: Add args empty - do manual add once first"); return end
    log("AUTO ADD -> fire " .. r.Name)
    if r:IsA("RemoteEvent") then pcall(function() r:FireServer(unpack(args)) end) end
end

local function resolveTarget(text)
    text = str_trim(text or "")
    if text == "" then return nil end
    if tonumber(text) then return Players:GetPlayerFromUserId(tonumber(text)) end
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Name:lower() == text:lower() then return p end
    end
    return nil
end

local function dumpRemotes()
    scanRemotes()
    log("DUMP (" .. #allRemotes .. " remotes) - cherchez TradeAccept / TradeAddItem")
    for _, r in ipairs(allRemotes) do
        log(string.format("  %s  %s", (r:IsA("RemoteFunction") and "RF" or "RE"), r:GetFullName()))
    end
    log("COPIEZ LES NOMS EXACTS DANS CONFIG (lignes ~35-36)")
end

-- ===== UI HELPERS =====
local C = {
    BG = Color3.fromRGB(10,14,26), CARD = Color3.fromRGB(18,24,42),
    CARD_HOVER = Color3.fromRGB(24,32,56), BORDER = Color3.fromRGB(40,55,90),
    ACCENT = Color3.fromRGB(77,159,255), ACCENT_DIM = Color3.fromRGB(50,110,200),
    TEXT = Color3.fromRGB(255,255,255), TEXT_SEC = Color3.fromRGB(107,122,153),
    TEXT_DIM = Color3.fromRGB(70,82,110), GLOW = Color3.fromRGB(77,159,255),
    SUCCESS = Color3.fromRGB(80,255,140), DANGER = Color3.fromRGB(255,90,90),
    INPUT_BG = Color3.fromRGB(14,18,34), TOGGLE_OFF = Color3.fromRGB(40,50,80),
    TOGGLE_ON = Color3.fromRGB(77,159,255),
    HEADER_TOP = Color3.fromRGB(30,45,90), HEADER_BOT = Color3.fromRGB(18,24,50),
}

local function corner(p, r) local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, r or 8); c.Parent = p; return c end
local function grad(p, t, b, rot) local g = Instance.new("UIGradient"); g.Color = ColorSequence.new({ColorSequenceKeypoint.new(0,t),ColorSequenceKeypoint.new(1,b)}); if rot then g.Rotation = rot end; g.Parent = p; return g end
local function stroke(p, col, th) local s = Instance.new("UIStroke"); s.Color = col; s.Thickness = th or 1; s.Parent = p; return s end
local function lbl(p, props)
    local l = Instance.new("TextLabel")
    l.BackgroundTransparency = 1; l.Font = props.font or Enum.Font.Gotham
    l.TextSize = props.size or 14; l.TextColor3 = props.color or C.TEXT
    l.Text = props.text or ""; l.TextXAlignment = props.xalign or Enum.TextXAlignment.Left
    l.TextYAlignment = Enum.TextYAlignment.Center
    l.Size = props.size2d or UDim2.new(1,0,1,0); l.Position = props.pos or UDim2.new(0,0,0,0)
    l.Parent = p; return l
end

local function createBtn(parent, text, color, pos, size, callback)
    local b = Instance.new("TextButton")
    b.BackgroundColor3 = color; b.Text = text; b.TextColor3 = Color3.fromRGB(255,255,255)
    b.Font = Enum.Font.GothamBold; b.TextSize = 13; b.BorderSizePixel = 0
    b.Position = pos; b.Size = size; b.Parent = parent
    corner(b, 8)
    b.MouseButton1Click:Connect(callback)
    b.MouseEnter:Connect(function() TweenService:Create(b, TweenInfo.new(0.1), {BackgroundColor3 = color:Lerp(Color3.new(1,1,1), 0.2)}):Play() end)
    b.MouseLeave:Connect(function() TweenService:Create(b, TweenInfo.new(0.1), {BackgroundColor3 = color}):Play() end)
    return b
end

local function createToggle(parent, name, order, callback)
    local row = Instance.new("Frame")
    row.Name = "T_"..name; row.Size = UDim2.new(1, -20, 0, 40); row.Position = UDim2.new(0, 10, 0, 0)
    row.BackgroundColor3 = C.CARD; row.BorderSizePixel = 0; row.Parent = parent
    corner(row, 8); stroke(row, C.BORDER, 1)

    lbl(row, {text=name, size=14, color=C.TEXT, font=Enum.Font.GothamMedium, pos=UDim2.new(0,12,0,0), size2d=UDim2.new(1,-100,1,0)})

    local status = Instance.new("TextLabel")
    status.BackgroundTransparency=1; status.Text="OFF"; status.TextColor3=C.TEXT_DIM; status.Font=Enum.Font.GothamBold; status.TextSize=11
    status.TextXAlignment=Enum.TextXAlignment.Right; status.Size=UDim2.new(0,50,1,0); status.Position=UDim2.new(1,-100,0,0); status.Parent=row

    local track = Instance.new("Frame")
    track.Size=UDim2.fromOffset(44,22); track.Position=UDim2.new(1,-52,0.5,0); track.AnchorPoint=Vector2.new(0,0.5)
    track.BackgroundColor3=C.TOGGLE_OFF; track.BorderSizePixel=0; track.Parent=row; corner(track,11)

    local knob = Instance.new("Frame")
    knob.Size=UDim2.fromOffset(18,18); knob.Position=UDim2.new(0,2,0.5,0); knob.AnchorPoint=Vector2.new(0,0.5)
    knob.BackgroundColor3=Color3.fromRGB(255,255,255); knob.BorderSizePixel=0; knob.Parent=track; corner(knob,9)

    local enabled = false
    local function set(val)
        enabled = val
        TweenService:Create(knob, TweenInfo.new(0.15, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position=val and UDim2.new(1,-20,0.5,0) or UDim2.new(0,2,0.5,0)}):Play()
        TweenService:Create(track, TweenInfo.new(0.15), {BackgroundColor3=val and C.TOGGLE_ON or C.TOGGLE_OFF}):Play()
        status.Text = val and "ON" or "OFF"; status.TextColor3 = val and C.SUCCESS or C.TEXT_DIM
        if callback then callback(val) end
    end
    row.InputBegan:Connect(function(inp) if inp.UserInputType==Enum.UserInputType.MouseButton1 then set(not enabled) end end)
    return {row=row, isEnabled=function() return enabled end, setEnabled=set}
end

-- ===== UI BUILD =====
local screenGui, mainFrame, header
local uiOpen = false
local savedPos = UDim2.fromOffset(400, 200) -- Position par defaut (offset)
local CLOSED_POS = UDim2.fromOffset(-500, 200) -- Hors ecran a gauche

local function animateOpen()
    uiOpen = true
    mainFrame.Visible = true
    mainFrame.Position = CLOSED_POS
    TweenService:Create(mainFrame, TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = savedPos}):Play()
end

local function animateClose()
    uiOpen = false
    TweenService:Create(mainFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {Position = CLOSED_POS}):Play()
    task.wait(0.3)
    if not uiOpen then mainFrame.Visible = false end
end

local function toggleUI()
    if uiOpen then animateClose() else animateOpen() end
end

local function createUI()
    screenGui = Instance.new("ScreenGui")
    screenGui.Name = "ZYROScriptGUI"
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.ResetOnSpawn = false
    screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

    -- MAIN FRAME : AnchorPoint (0,0) = TopLeft, Position en OFFSET uniquement
    mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.fromOffset(320, 380)
    mainFrame.Position = CLOSED_POS
    mainFrame.AnchorPoint = Vector2.new(0, 0)
    mainFrame.BackgroundColor3 = C.BG
    mainFrame.BackgroundTransparency = 0.05
    mainFrame.BorderSizePixel = 0
    mainFrame.Visible = false
    mainFrame.Parent = screenGui
    corner(mainFrame, 12)
    stroke(mainFrame, C.BORDER, 1.5)

    -- Glow arriere
    local frameGlow = Instance.new("Frame")
    frameGlow.Size = UDim2.fromScale(1,1); frameGlow.Position = UDim2.new(0,-8,0,-8)
    frameGlow.BackgroundColor3 = C.GLOW; frameGlow.BackgroundTransparency = 0.85; frameGlow.BorderSizePixel = 0; frameGlow.ZIndex = -1
    frameGlow.Parent = mainFrame; corner(frameGlow, 20)

    -- HEADER (Drag Zone)
    header = Instance.new("Frame")
    header.Name = "Header"
    header.Size = UDim2.new(1, 0, 0, 44)
    header.Position = UDim2.new(0, 0, 0, 0)
    header.BackgroundColor3 = C.HEADER_TOP
    header.BorderSizePixel = 0
    header.Parent = mainFrame
    corner(header, 12)
    grad(header, C.HEADER_TOP, C.HEADER_BOT, 90)
    stroke(header, C.BORDER, 1)

    -- Fix corners bas du header (pour pas casser le round du mainFrame)
    local headerFix = Instance.new("Frame")
    headerFix.Size = UDim2.new(1, 0, 0, 12)
    headerFix.Position = UDim2.new(0, 0, 1, -12)
    headerFix.BackgroundColor3 = C.HEADER_TOP
    headerFix.BorderSizePixel = 0
    headerFix.ZIndex = 0
    headerFix.Parent = header

    lbl(header, {text="[Z] ZYROSCRIPT", size=16, color=C.TEXT, font=Enum.Font.GothamBold, pos=UDim2.new(0,14,0,0), size2d=UDim2.new(1,-100,1,0)})
    lbl(header, {text="Anime Dice Trade", size=10, color=C.TEXT_SEC, pos=UDim2.new(0,14,0,22), size2d=UDim2.new(1,-100,0,16)})

    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.fromOffset(26,26); closeBtn.Position = UDim2.new(1, -32, 0.5, 0); closeBtn.AnchorPoint = Vector2.new(0,0.5)
    closeBtn.BackgroundColor3 = Color3.fromRGB(30,40,70); closeBtn.Text = "X"; closeBtn.TextColor3 = C.TEXT_SEC
    closeBtn.Font = Enum.Font.GothamBold; closeBtn.TextSize = 14; closeBtn.BorderSizePixel = 0; closeBtn.Parent = header; corner(closeBtn, 6)
    closeBtn.MouseButton1Click:Connect(toggleUI)

    -- CONTENT (pas de UIListLayout, placement manuel Y)
    local content = Instance.new("Frame")
    content.Name = "Content"
    content.Size = UDim2.new(1, -20, 1, -54)
    content.Position = UDim2.new(0, 10, 0, 50)
    content.BackgroundTransparency = 1
    content.Parent = mainFrame

    -- TARGET SECTION
    local y = 0
    lbl(content, {text="TARGET PLAYER", size=11, color=C.ACCENT, font=Enum.Font.GothamBold, pos=UDim2.new(0,0,0,y), size2d=UDim2.new(1,0,0,16)}); y = y + 18

    local searchBox = Instance.new("TextBox")
    searchBox.Size = UDim2.new(1, -90, 0, 32); searchBox.Position = UDim2.new(0, 0, 0, y)
    searchBox.BackgroundColor3 = C.INPUT_BG; searchBox.BackgroundTransparency = 0.1
    searchBox.PlaceholderText = "Nom ou UserId..."; searchBox.PlaceholderColor3 = C.TEXT_DIM; searchBox.TextColor3 = C.TEXT
    searchBox.Font = Enum.Font.Gotham; searchBox.TextSize = 13; searchBox.BorderSizePixel = 0; searchBox.ClearTextOnFocus = false; searchBox.Parent = content
    corner(searchBox, 6); local sStroke = stroke(searchBox, C.BORDER, 1)
    searchBox.Focused:Connect(function() TweenService:Create(sStroke, TweenInfo.new(0.15), {Color=C.ACCENT}):Play() end)
    searchBox.FocusLost:Connect(function() TweenService:Create(sStroke, TweenInfo.new(0.15), {Color=C.BORDER}):Play() end)

    local searchBtn = createBtn(content, "Search", C.ACCENT, UDim2.new(1, -85, 0, y), UDim2.fromOffset(80, 32), function()
        local found = resolveTarget(searchBox.Text)
        if found then
            targetPlayer = found; searchBox.Text = found.Name
            targetStatus.Text = "CIBLE: " .. found.Name; targetStatus.TextColor3 = C.SUCCESS
            if tForce.isEnabled() then doForceAccept() end
            if tAuto.isEnabled() then doAutoAdd() end
        else
            targetStatus.Text = "INTROUVABLE"; targetStatus.TextColor3 = C.DANGER
        end
    end)
    y = y + 38

    local targetStatus = Instance.new("TextLabel")
    targetStatus.Name = "TargetStatus"
    targetStatus.BackgroundTransparency = 1; targetStatus.Text = "En attente..."; targetStatus.TextColor3 = C.TEXT_DIM
    targetStatus.Font = Enum.Font.Gotham; targetStatus.TextSize = 11
    targetStatus.Size = UDim2.new(1, 0, 0, 16); targetStatus.Position = UDim2.new(0, 0, 0, y)
    targetStatus.TextXAlignment = Enum.TextXAlignment.Left; targetStatus.Parent = content
    y = y + 22

    -- OPTIONS SECTION
    lbl(content, {text="OPTIONS", size=11, color=C.ACCENT, font=Enum.Font.GothamBold, pos=UDim2.new(0,0,0,y), size2d=UDim2.new(1,0,0,16)}); y = y + 18

    local togglesFrame = Instance.new("Frame")
    togglesFrame.Size = UDim2.new(1, 0, 0, 130)
    togglesFrame.Position = UDim2.new(0, 0, 0, y)
    togglesFrame.BackgroundTransparency = 1
    togglesFrame.Parent = content

    local tList = Instance.new("UIListLayout")
    tList.Padding = UDim.new(0, 8)
    tList.SortOrder = Enum.SortOrder.LayoutOrder
    tList.Parent = togglesFrame

    local tForce  = createToggle(togglesFrame, "Force Accept (Auto)", 1, function(on) if on then doForceAccept() end end)
    local tAuto   = createToggle(togglesFrame, "Auto Add All (Once)", 2, function(on) if on then doAutoAdd() end end)
    -- Freeze retire

    y = y + 140

    -- FOOTER
    local footer = Instance.new("Frame")
    footer.Size = UDim2.new(1, 0, 0, 30)
    footer.Position = UDim2.new(0, 0, 1, -30)
    footer.BackgroundTransparency = 1
    footer.Parent = mainFrame

    lbl(footer, {text="RightShift = Toggle | Drag Header = Move", size=9, color=C.TEXT_DIM, font=Enum.Font.Gotham, pos=UDim2.new(0,0,0,0), size2d=UDim2.new(1,-120,1,0)})

    local dumpBtn = createBtn(footer, "Dump Remotes", C.CARD, UDim2.new(1, -110, 0.5, 0), UDim2.fromOffset(100, 22), dumpRemotes)
    dumpBtn.AnchorPoint = Vector2.new(0, 0.5)
    dumpBtn.TextSize = 10

    -- ===== DRAG LOGIC (ROBUSTE) =====
    local dragging = false
    local dragStart = nil
    local frameStartPos = nil

    header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            frameStartPos = mainFrame.Position
            -- Visual feedback
            TweenService:Create(header, TweenInfo.new(0.1), {BackgroundTransparency = 0.1}):Play()
        end
    end)

    header.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            local newX = frameStartPos.X.Offset + delta.X
            local newY = frameStartPos.Y.Offset + delta.Y
            local vp = workspace.CurrentCamera.ViewportSize
            local fs = mainFrame.AbsoluteSize
            newX = math.clamp(newX, 0, vp.X - fs.X)
            newY = math.clamp(newY, 0, vp.Y - fs.Y)
            mainFrame.Position = UDim2.fromOffset(newX, newY)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 and dragging then
            dragging = false
            savedPos = mainFrame.Position -- Sauvegarde pour prochaine ouverture
            TweenService:Create(header, TweenInfo.new(0.1), {BackgroundTransparency = 0}):Play()
        end
    end)

    -- KEYBIND
    UserInputService.InputBegan:Connect(function(inp, gp)
        if not gp and inp.KeyCode == Enum.KeyCode.RightShift then toggleUI() end
    end)

    return {toggles={["Force Accept"]=tForce, ["Auto Add All"]=tAuto}, searchBox=searchBox, targetStatus=targetStatus}
end

-- ===== START =====
local ok, err = pcall(function()
    local ui = createUI()
    scanRemotes()
    enableNamecallHook()
    log("READY v4.0 - RightShift to toggle | Drag Header to move")
    log("WORKFLOW: 1) Open trade 2) Manual Add+Accept (capture args) 3) Dump Remotes 4) Edit CONFIG 5) Re-execute 6) Toggle options")
end)

if not ok then
    warn("ZYROSCRIPT FATAL: " .. tostring(err))
end
