local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

local RUNNING = true
local COOLDOWN = 35
local TARGET = 7

local doors = {}
local recorded = false

-- Scan : cherche DoorOpenerScript, puis fouille SON MODEL PARENT pour trouver Part + Prompt
local function scanDoors()
    doors = {}
    for _, scriptObj in ipairs(Workspace:GetDescendants()) do
        if scriptObj:IsA("Script") and scriptObj.Name == "DoorOpenerScript" then
            local model = scriptObj.Parent -- Le Model "DoorOpener"
            if model and model:IsA("Model") then
                -- Cherche BasePart + ProximityPrompt DANS ce Model
                for _, child in ipairs(model:GetDescendants()) do
                    if child:IsA("BasePart") then
                        local prompt = child:FindFirstChildWhichIsA("ProximityPrompt")
                        if prompt then
                            table.insert(doors, {part = child, prompt = prompt, model = model})
                            print("[FARM] Porte verrouillée : " .. model:GetFullName() .. " | Part: " .. child.Name)
                            break -- Une seule porte par model
                        end
                    end
                end
            end
        end
    end
    recorded = true
    print("[FARM] Enregistrement fini. " .. #doors .. " portes verrouillées.")
end

task.spawn(function()
    -- Attend d'avoir 7 portes
    while not recorded or #doors < TARGET do
        scanDoors()
        if #doors >= TARGET then break end
        task.wait(2)
    end

    if #doors == 0 then
        warn("[FARM] ERREUR : Aucune porte avec Prompt trouvée dans les Models DoorOpener.")
        return
    end

    -- Boucle farm
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
                    print("[FARM] TP " .. i .. "/" .. #doors .. " -> Prompt fired (" .. door.part.Name .. ")")
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
