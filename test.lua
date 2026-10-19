local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

local RUNNING = true
local COOLDOWN = 35
local TARGET = 7

local doors = {}
local recorded = false

-- Scan ULTRA LARGE : cherche TOUS les ProximityPrompt dans Workspace.Halloween
-- Garde ceux qui ont un DoorOpenerScript comme ancêtre
local function scanDoors()
    doors = {}
    local halloween = Workspace:FindFirstChild("Halloween")
    if not halloween then warn("[FARM] Dossier 'Halloween' introuvable dans Workspace") return end

    for _, obj in ipairs(halloween:GetDescendants()) do
        if obj:IsA("ProximityPrompt") then
            -- Remonte les ancêtres pour voir s'il y a un DoorOpenerScript
            local current = obj.Parent
            local foundScript = false
            for _ = 1, 6 do
                if current and current.Name == "DoorOpenerScript" then foundScript = true break end
                if current and current:FindFirstChild("DoorOpenerScript") then foundScript = true break end
                current = current.Parent
                if not current then break end
            end

            if foundScript then
                -- Trouve la Part (Parent du Prompt ou Parent de l'Attachment)
                local part = obj.Parent
                if part:IsA("Attachment") then part = part.Parent end
                if part:IsA("BasePart") then
                    table.insert(doors, {part = part, prompt = obj})
                    print("[FARM] Porte verrouillée : " .. part:GetFullName() .. " | Prompt: " .. obj.Name)
                end
            end
        end
    end

    recorded = true
    print("[FARM] Enregistrement fini. " .. #doors .. " portes verrouillées.")
end

task.spawn(function()
    while not recorded or #doors < TARGET do
        scanDoors()
        if #doors >= TARGET then break end
        task.wait(2)
    end

    if #doors == 0 then
        warn("[FARM] ERREUR : Aucun ProximityPrompt lié à DoorOpenerScript trouvé dans Halloween.")
        return
    end

    while RUNNING do
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp then
            for i, door in ipairs(doors) do
                if not RUNNING then break end
                if door.part and door.part.Parent then
                    pcall(function()
                        hrp.CFrame = door.part.CFrame + Vector3.new(0, 5, 0)
                        fireproximityprompt(door.prompt, 1)
                    end)
                    print("[FARM] TP " .. i .. "/" .. #doors .. " -> Fired (" .. door.part.Name .. ")")
                    task.wait(1.5)
                end
            end
        else
            task.wait(3)
        end
        if RUNNING then
            print("[FARM] Tour fini. Pause " .. COOLDOWN .. "s.")
            task.wait(COOLDOWN)
        end
    end
end)

print("[FARM] Script lancé. F9 pour logs. RUNNING = false pour arrêter.")
