Shared = {}

-- Placeholder for time check (handled server-side)
function Shared:IsWithinSpawnHours()
    return true -- Temporarily return true; server will handle this
end

-- Get closest dead player
function Shared:GetClosestDeadPlayer(coords)
    local players = GetActivePlayers()
    local closestPlayer, closestDistance = nil, 5.0
    for _, player in ipairs(players) do
        local ped = GetPlayerPed(player)
        if IsEntityDead(ped) then
            local playerCoords = GetEntityCoords(ped)
            local distance = #(coords - playerCoords)
            if distance < closestDistance then
                closestPlayer = GetPlayerServerId(player)
                closestDistance = distance
            end
        end
    end
    return closestPlayer, closestDistance
end