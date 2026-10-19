local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

local RUNNING = true
local COOLDOWN = 35

local DOOR_NAMES = {
    "Door", "Door1", "Door2", "Door3", "Door4", "Door5", "Door6", "Door7",
    "House", "House1", "House2", "House3", "House4", "House5", "House6", "House7",
    "HauntedHouse", "PumpkinHouse", "CandyHouse",
    "Entrance", "Gate", "Portal",
}

local doors = {}

local function findDoors()
    doors = {}
    print("[FARM] Recherche des portes...")
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if (obj:IsA("BasePart") or obj:IsA("MeshPart")) then
            local nameLower = obj.Name:lower()
            for _, keyword in ipairs(DOOR_NAMES) do
                if nameLower:find(keyword:lower()) then
                    if obj:FindFirstChildWhichIsA("TouchInterest") or obj:FindFirstChildWhichIsA("TouchTransmitter") then
                        table.insert(doors, obj)
                        print("[FARM] Porte trouvee : " .. obj:GetFullName())
                        break
                    end
                end
            end
        end
    end
    if #doors == 0 then
        warn("[FARM] AUCUNE PORTE TROUVEE. Verifie DOOR_NAMES.")
    else
        print("[FARM] " .. #doors .. " porte(s) detectee(s). Demarrage boucle.")
    end
end

spawn(function()
    findDoors()
    if #doors == 0 then return end

    while RUNNING do
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp then
            for i, door in ipairs(doors) do
                if not RUNNING then break end
                if door and door.Parent then
                    pcall(function()
                        hrp.CFrame = door.CFrame + Vector3.new(0, 5, 0)
                    end)
                    print("[FARM] TP Maison " .. i .. "/" .. #doors .. " (" .. door.Name .. ")")
                    wait(1.5)
                else
                    warn("[FARM] Porte " .. i .. " disparue, re-scan...")
                    findDoors()
                    break
                end
            end
        else
            wait(3)
        end

        if RUNNING then
            print("[FARM] Tour fini. Attente cooldown " .. COOLDOWN .. "s...")
            wait(COOLDOWN)
        end
    end
end)

print("[FARM] Script lance. F9 pour logs. Tape RUNNING = false pour arreter.")
