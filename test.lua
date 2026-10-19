local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

local RUNNING = true
local COOLDOWN = 35
local TARGET_COUNT = 7

local doors = {}
local recorded = false

-- 1. SCAN : cherche les DoorOpenerScript dans Workspace
local function scanDoors()
    doors = {}
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Script") and obj.Name == "DoorOpenerScript" then
            local model = obj.Parent
            local part = model:IsA("BasePart") and model or model:FindFirstChildWhichIsA("BasePart")
            local prompt = part and part:FindFirstChildWhichIsA("ProximityPrompt")
            if part and prompt then
                table.insert(doors, {part = part, prompt = prompt})
                print("[FARM] Porte trouvée : " .. model:GetFullName())
            end
        end
    end
    recorded = true
    print("[FARM] Enregistrement fini. " .. #doors .. " portes verrouillées.")
end

-- 2. BOUCLE PRINCIPALE
task.spawn(function()
    -- Attend d'avoir 7 portes
    while not recorded or #doors < TARGET_COUNT do
        scanDoors()
        if #doors >= TARGET_COUNT then break end
        task.wait(2)
    end

    if #doors == 0 then
        warn("[FARM] ERREUR : Aucun DoorOpenerScript trouvé. Vérifie que le script est bien dans Workspace.")
        return
    end

    -- Farm infini sur les 7 portes
    while RUNNING do
        local character = LocalPlayer.Character
        local hrp = character and character:FindFirstChild("HumanoidRootPart")
        
        if hrp then
            for i, door in ipairs(doors) do
                if not RUNNING then break end
                if door.part and door.part.Parent then
                    -- TP au-dessus de la porte
                    hrp.CFrame = door.part.CFrame + Vector3.new(0, 5, 0)
                    -- Appuie sur le prompt (E)
                    fireproximityprompt(door.prompt, 1)
                    print("[FARM] TP " .. i .. "/" .. #doors .. " -> Prompt déclenché")
                    task.wait(1.5) -- temps que la porte s'ouvre + donne loot
                end
            end
        else
            task.wait(3) -- attend respawn
        end

        if RUNNING then
            print("[FARM] Tour terminé. Pause " .. COOLDOWN .. "s (cooldown).")
            task.wait(COOLDOWN)
        end
    end
end)

print("[FARM] Script lancé. Ouvre la console (F9) pour voir les logs. Tape RUNNING = false pour arrêter.")
