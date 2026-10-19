-- AUTO PUMPKIN/CANDY v3 — TouchInterest / Teleport to items
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

local RUNNING = true
local TP_DELAY = 0.5 -- délai entre chaque TP (anti-kick)

print("[PUMPKIN] v3 Touch/TP démarré.")

-- Liste des noms à chercher (ajoute les tiens si différents)
local TARGET_NAMES = {
    "pumpkin", "citrouille", "candy", "bonbon", "halloween", "treat", "sweet", "lollipop"
}

local function isTarget(obj)
    local n = obj.Name:lower()
    for _, kw in ipairs(TARGET_NAMES) do
        if n:find(kw) then return true end
    end
    return false
end

task.spawn(function()
    while RUNNING do
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp then
            for _, obj in ipairs(Workspace:GetDescendants()) do
                if (obj:IsA("BasePart") or obj:IsA("MeshPart")) and isTarget(obj) then
                    -- Vérifie s'il a un TouchInterest (script qui détecte le toucher)
                    if obj:FindFirstChildWhichIsA("TouchInterest") or obj:FindFirstChildWhichIsA("TouchTransmitter") then
                        pcall(function()
                            hrp.CFrame = obj.CFrame + Vector3.new(0, 3, 0) -- TP au-dessus
                            print("[PUMPKIN] TP vers : " .. obj:GetFullName())
                        end)
                        task.wait(TP_DELAY)
                    end
                end
            end
        end
        task.wait(1) -- scan moins fréquent
    end
end)
