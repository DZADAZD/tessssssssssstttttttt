-- SCANNER EVENT HALLOWEEN — Colle, Execute, approche-toi d'une citrouille/maison
-- Ça va lister TOUS les objets interactifs dans un rayon de 50 studs

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

local RADIUS = 50
local scanned = {}

print("=== SCANNER DÉMARRÉ (rayon " .. RADIUS .. " studs) ===")
print("Approche-toi d'une citrouille/maison/bonbon...")

task.spawn(function()
    while true do
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp then
            for _, obj in ipairs(Workspace:GetDescendants()) do
                if obj:IsA("BasePart") or obj:IsA("MeshPart") or obj:IsA("Part") then
                    local dist = (obj.Position - hrp.Position).Magnitude
                    if dist <= RADIUS then
                        local key = obj:GetFullName()
                        if not scanned[key] then
                            scanned[key] = true
                            local info = {}
                            table.insert(info, "Dist: " .. math.floor(dist))
                            table.insert(info, "Class: " .. obj.ClassName)
                            table.insert(info, "Name: " .. obj.Name)
                            table.insert(info, "Parent: " .. (obj.Parent and obj.Parent.Name or "nil"))
                            
                            -- Cherche ce qui rend l'objet interactif
                            local prompt = obj:FindFirstChildWhichIsA("ProximityPrompt")
                            local click = obj:FindFirstChildWhichIsA("ClickDetector")
                            local touch = obj:FindFirstChildWhichIsA("TouchInterest") or obj:FindFirstChildWhichIsA("TouchTransmitter")
                            local script = obj:FindFirstChildWhichIsA("Script") or obj:FindFirstChildWhichIsA("LocalScript")
                            local remote = obj:FindFirstChildWhichIsA("RemoteEvent") or obj:FindFirstChildWhichIsA("RemoteFunction")
                            
                            if prompt then table.insert(info, "🟢 ProximityPrompt: '" .. prompt.Name .. "' (Action: " .. prompt.ActionText .. ")") end
                            if click then table.insert(info, "🔵 ClickDetector: '" .. click.Name .. "'") end
                            if touch then table.insert(info, "🟡 TouchInterest/TouchTransmitter") end
                            if script then table.insert(info, "🟣 Script: '" .. script.Name .. "'") end
                            if remote then table.insert(info, "🔴 Remote: '" .. remote.Name .. "'") end
                            
                            -- Attributs utiles
                            for _, attr in ipairs(obj:GetAttributes()) do
                                table.insert(info, "🏷️ Attr " .. attr .. " = " .. tostring(obj:GetAttribute(attr)))
                            end
                            
                            if #info > 4 then -- Affiche seulement s'il y a un truc interactif
                                print("--- OBJET INTERACTIF TROUVÉ ---")
                                for _, line in ipairs(info) do print(line) end
                                print("-------------------------------")
                            end
                        end
                    end
                end
            end
        end
        task.wait(2) -- Scan toutes les 2s
    end
end)
