local QBCore = exports['qb-core']:GetCoreObject()
local peds = {} -- Table to store spawned PEDs
local deathPed = nil -- Death PED in morgue
local isNearPed = false
local canSpawnPed = false
local debugSolo = true -- Temporary: Force "Press E" for solo testing (set to false for live)
local wasNearPed = false -- Track state to reduce debug spam
local closestPedIndex = nil -- Track the closest PED for interaction
local lastEPress = 0 -- Debounce for E key
local isReviving = false -- Track revive state
local remainingMorgueTime = 0 -- Track remaining morgue time
local showMorgueTimer = false -- Control timer display

-- Function to draw 2D text on screen
local function DrawText2D(x, y, text, scale)
    SetTextFont(4)
    SetTextScale(scale, scale)
    SetTextColour(255, 255, 255, 255)
    SetTextEntry("STRING")
    AddTextComponentString(text)
    DrawText(x, y)
    SetTextCentre(true)
end

-- Request spawn status from server
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1000)
        TriggerServerEvent('undertaker:checkSpawnHours')
    end
end)

-- Receive spawn status from server
RegisterNetEvent('undertaker:setSpawnStatus')
AddEventHandler('undertaker:setSpawnStatus', function(canSpawn)
    canSpawnPed = canSpawn
end)

-- Spawn/despawn undertaker PEDs
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1000)
        if Config.EnableUndertaker and canSpawnPed then
            for i, pedData in ipairs(Config.Peds) do
                if not peds[i] then
                    RequestModel(pedData.model)
                    while not HasModelLoaded(pedData.model) do
                        Citizen.Wait(100)
                    end
                    peds[i] = CreatePed(4, pedData.model, pedData.coords.x, pedData.coords.y, pedData.coords.z, pedData.coords.w, false, true)
                    FreezeEntityPosition(peds[i], true)
                    SetEntityInvincible(peds[i], true)
                    SetBlockingOfNonTemporaryEvents(peds[i], true)
                end
            end
        else
            for i, ped in ipairs(peds) do
                if ped then
                    DeleteEntity(ped)
                    peds[i] = nil
                end
            end
        end
    end
end)

-- Handle "Press E" prompt and burial interaction for each PED
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0) -- Needs to be fast for smooth text drawing
        if Config.EnableUndertaker and #peds > 0 then
            local playerPed = PlayerPedId()
            local playerCoords = GetEntityCoords(playerPed)
            isNearPed = false
            closestPedIndex = nil
            local closestDistance = 3.0

            -- Find the closest PED
            for i, pedData in ipairs(Config.Peds) do
                if peds[i] then
                    local distance = #(playerCoords - vector3(pedData.coords.x, pedData.coords.y, pedData.coords.z))
                    if distance < closestDistance then
                        closestPedIndex = i
                        closestDistance = distance
                        isNearPed = true
                    end
                end
            end

            -- Handle proximity state for debug
            if isNearPed and not wasNearPed then
                print('[DEBUG] Near PED #' .. closestPedIndex .. ' at distance: ' .. closestDistance)
                wasNearPed = true
            elseif not isNearPed and wasNearPed then
                wasNearPed = false
            end

            -- Draw prompt for the closest PED
            if isNearPed then
                local pedData = Config.Peds[closestPedIndex]
                local closestPlayer, _ = Shared:GetClosestDeadPlayer(playerCoords)
                if closestPlayer or debugSolo then
                    QBCore.Functions.DrawText3D(pedData.coords.x, pedData.coords.y, pedData.coords.z + 1.0, '[E] Bury Body ($1M)')
                end
            end
        end
    end
end)

-- Separate thread for E key detection to avoid input lag
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0) -- Needs to be fast for input detection
        if isNearPed and closestPedIndex then
            local playerPed = PlayerPedId()
            local playerCoords = GetEntityCoords(playerPed)
            local closestPlayer, _ = Shared:GetClosestDeadPlayer(playerCoords)
            if closestPlayer or debugSolo then
                if IsControlJustPressed(0, 38) then -- E key
                    local currentTime = GetGameTimer()
                    if currentTime - lastEPress > 1000 then -- 1-second debounce
                        lastEPress = currentTime
                        print('[DEBUG] E key pressed for PED #' .. closestPedIndex)
                        TriggerServerEvent('undertaker:requestBurial', closestPlayer or GetPlayerServerId(PlayerId())) -- Use self if solo
                    end
                end
            end
        end
    end
end)

-- Play burial animation
RegisterNetEvent('undertaker:playBurialAnimation')
AddEventHandler('undertaker:playBurialAnimation', function()
    for _, ped in ipairs(peds) do
        if ped then
            RequestAnimDict('amb@world_human_gardener_plant@male@base')
            while not HasAnimDictLoaded('amb@world_human_gardener_plant@male@base') do
                Citizen.Wait(100)
            end
            TaskPlayAnim(ped, 'amb@world_human_gardener_plant@male@base', 'base', 8.0, -8.0, 5000, 1, 0, false, false, false)
        end
    end
end)

-- Teleport to morgue and spawn Death PED
RegisterNetEvent('undertaker:teleportToMorgue')
AddEventHandler('undertaker:teleportToMorgue', function()
    QBCore.Functions.Notify('You’ve been buried!', 'error')
    DoScreenFadeOut(1000)
    Citizen.Wait(1000)
    local playerPed = PlayerPedId()
    print('[DEBUG] Player state before morgue - IsEntityDead: ' .. tostring(IsEntityDead(playerPed)) .. ', Health: ' .. tostring(GetEntityHealth(playerPed)))
    
    -- Teleport to morgue
    SetEntityCoords(playerPed, Config.MorgueCoords.x, Config.MorgueCoords.y, Config.MorgueCoords.z, false, false, false, true)
    SetEntityHeading(playerPed, Config.MorgueCoords.w)
    
    -- Spawn Death PED
    if not deathPed then
        RequestModel(Config.DeathPed.model)
        while not HasModelLoaded(Config.DeathPed.model) do
            Citizen.Wait(100)
        end
        deathPed = CreatePed(4, Config.DeathPed.model, Config.DeathPed.coords.x, Config.DeathPed.coords.y, Config.DeathPed.coords.z, Config.DeathPed.coords.w, false, true)
        FreezeEntityPosition(deathPed, false) -- Allow movement
        SetEntityInvincible(deathPed, true)
        SetBlockingOfNonTemporaryEvents(deathPed, true)
        print('[DEBUG] Spawned Death PED in morgue')
        
        -- Automatically start revive process
        Citizen.CreateThread(function()
            local playerCoords = GetEntityCoords(playerPed)
            TaskGoToCoordAnyMeans(deathPed, playerCoords.x, playerCoords.y, playerCoords.z, 1.0, 0, 0, 786603, 0xbf800000)
            local dist = #(GetEntityCoords(deathPed) - playerCoords)
            while dist > 1.0 do
                Citizen.Wait(200)
                playerCoords = GetEntityCoords(playerPed)
                dist = #(GetEntityCoords(deathPed) - playerCoords)
                if dist > 1.0 then
                    TaskGoToCoordAnyMeans(deathPed, playerCoords.x, playerCoords.y, playerCoords.z, 1.0, 0, 0, 786603, 0xbf800000)
                end
            end
            
            -- Perform revive animation and revive player
            RequestAnimDict("mini@cpr@char_a@cpr_str")
            while not HasAnimDictLoaded("mini@cpr@char_a@cpr_str") do
                Citizen.Wait(100)
            end
            TaskPlayAnim(deathPed, "mini@cpr@char_a@cpr_str", "cpr_pumpchest", 1.0, 1.0, -1, 9, 1.0, 0, 0, 0)
            QBCore.Functions.Progressbar("revive_death", "Death is reviving you...", Config.DeathPed.reviveTime, false, false, {
                disableMovement = true,
                disableCarMovement = true,
                disableMouse = false,
                disableCombat = true,
            }, {}, {}, {}, function() -- Done
                ClearPedTasks(deathPed)
                -- Revive using qb-ambulancejob's client event
                TriggerEvent("hospital:client:Revive")
                StopScreenEffect('DeathFailOut')
                -- Additional revive steps to ensure state is cleared
                NetworkResurrectLocalPlayer(Config.MorgueCoords.x, Config.MorgueCoords.y, Config.MorgueCoords.z, Config.MorgueCoords.w, true, false)
                ResurrectPed(playerPed)
                SetEntityHealth(playerPed, 200)
                ClearPedBloodDamage(playerPed)
                ClearPedTasksImmediately(playerPed)
                print('[DEBUG] Player state after Death PED revive - IsEntityDead: ' .. tostring(IsEntityDead(playerPed)) .. ', Health: ' .. tostring(GetEntityHealth(playerPed)))
                QBCore.Functions.Notify('Death has given you a second chance at life...', 'success')
                isReviving = false

                -- Start morgue timer display
                remainingMorgueTime = Config.MorgueTime
                showMorgueTimer = true
                Citizen.CreateThread(function()
                    while showMorgueTimer and remainingMorgueTime > 0 do
                        Citizen.Wait(1000)
                        remainingMorgueTime = remainingMorgueTime - 1
                    end
                    showMorgueTimer = false
                end)
            end)
        end)
    end
    
    DoScreenFadeIn(1000)
    QBCore.Functions.Notify('You wake up in the morgue, cold and lifeless...', 'error')
end)

-- Display morgue timer
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if showMorgueTimer then
            local minutes = math.floor(remainingMorgueTime / 60)
            local seconds = remainingMorgueTime % 60
            local timerText = string.format("Time in Morgue: %02d:%02d", minutes, seconds)
            DrawText2D(0.5, 0.95, timerText, 0.5) -- Display at bottom center of screen
        end
    end
end)

-- Teleport to release point and despawn Death PED
RegisterNetEvent('undertaker:releaseFromMorgue')
AddEventHandler('undertaker:releaseFromMorgue', function()
    QBCore.Functions.Notify('You’ve been released from the morgue.', 'success')
    DoScreenFadeOut(1000)
    Citizen.Wait(1000)
    SetEntityCoords(PlayerPedId(), Config.ReleaseCoords.x, Config.ReleaseCoords.y, Config.ReleaseCoords.z, false, false, false, true)
    SetEntityHeading(PlayerPedId(), Config.ReleaseCoords.w)
    
    -- Despawn Death PED
    if deathPed then
        DeleteEntity(deathPed)
        deathPed = nil
        print('[DEBUG] Despawned Death PED')
    end
    
    -- Stop morgue timer display
    showMorgueTimer = false
    DoScreenFadeIn(1000)
end)