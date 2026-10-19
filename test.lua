-- AUTO PUMPKIN/CANDY — UNIVERSAL (essaie Prompt, Click, Touch, Remote)
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

local RUNNING = true
local RADIUS = 40
local KEYWORDS = {"pumpkin","citrouille","candy","bonbon","halloween","treat","sweet","lollipop"}

local function match(name)
    name = name:lower()
    for _,k in ipairs(KEYWORDS) do if name:find(k) then return true end end
    return false
end

print("[UNIVERSAL] Démarré. F9 pour logs.")

-- 1. ProximityPrompt + ClickDetector loop
task.spawn(function()
    while RUNNING do
        local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            for _, obj in ipairs(Workspace:GetDescendants()) do
                local part = obj:IsA("BasePart") and obj or obj:FindFirstChildWhichIsA("BasePart")
                if part and (part.Position - hrp.Position).Magnitude <= RADIUS then
                    local fullName = (obj.Name .. " " .. (obj.Parent and obj.Parent.Name or "")):lower()
                    if match(fullName) then
                        if obj:IsA("ProximityPrompt") then
                            pcall(fireproximityprompt, obj, 1)
                        elseif obj:IsA("ClickDetector") then
                            pcall(fireclickdetector, obj)
                        end
                    end
                end
            end
        end
        task.wait(0.3)
    end
end)

-- 2. TouchInterest TP (moins fréquent)
task.spawn(function()
    while RUNNING do
        local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            for _, part in ipairs(Workspace:GetDescendants()) do
                if part:IsA("BasePart") and match(part.Name) and part:FindFirstChildWhichIsA("TouchInterest") then
                    pcall(function() hrp.CFrame = part.CFrame + Vector3.new(0,3,0) end)
                    task.wait(0.4)
                end
            end
        end
        task.wait(1)
    end
end)

-- 3. Remote Sniffer (pour info)
local mt = getrawmetatable(game)
if mt then
    local old = mt.__namecall
    local sr = make_writeable or setreadonly
    if sr then pcall(function()
        sr(mt, false)
        mt.__namecall = newcclosure(function(self, ...)
            if (getnamecallmethod()=="FireServer" or getnamecallmethod()=="InvokeServer") and (self:IsA("RemoteEvent") or self:IsA("RemoteFunction")) then
                local n=self.Name:lower()
                if n:find("collect") or n:find("pumpkin") or n:find("candy") or n:find("halloween") or n:find("treat") then
                    print("[REMOTE SNIFF] "..self.Name.." -> "..table.concat({...}, ", "))
                end
            end
            return old(self, ...)
        end)
        sr(mt, true)
    end) end
end
