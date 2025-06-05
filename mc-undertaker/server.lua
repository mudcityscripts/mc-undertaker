local QBCore = exports['qb-core']:GetCoreObject()

-- Check if current time is within spawn hours (server-side)
local function IsWithinSpawnHours()
    local hour = tonumber(os.date('%H'))
    local startHour = Config.PedSpawnHours.start
    local finishHour = Config.PedSpawnHours.finish
    
    if startHour < finishHour then
        return hour >= startHour and hour < finishHour
    else
        return hour >= startHour or hour < finishHour
    end
end

-- Client requests if PED should spawn
RegisterNetEvent('undertaker:checkSpawnHours')
AddEventHandler('undertaker:checkSpawnHours', function()
    local src = source
    local canSpawn = IsWithinSpawnHours()
    TriggerClientEvent('undertaker:setSpawnStatus', src, canSpawn)
end)

-- Handle burial request
RegisterNetEvent('undertaker:requestBurial')
AddEventHandler('undertaker:requestBurial', function(targetPlayerId)
    local src = source
    print('[DEBUG] Server received undertaker:requestBurial for targetPlayerId: ' .. tostring(targetPlayerId)) -- Debug event receipt
    local Player = QBCore.Functions.GetPlayer(src)
    local TargetPlayer = QBCore.Functions.GetPlayer(targetPlayerId)

    if not Player or not TargetPlayer then
        QBCore.Functions.Notify(src, 'Invalid player.', 'error')
        print('[DEBUG] Invalid player: src=' .. tostring(src) .. ', target=' .. tostring(targetPlayerId))
        return
    end

    -- Check if target is dead or downed using QBCore metadata
    local targetData = TargetPlayer.PlayerData
    local isDead = targetData.metadata['isdead'] or false
    local isDowned = targetData.metadata['inlaststand'] or false
    print('[DEBUG] Death check - isdead: ' .. tostring(isDead) .. ', inlaststand: ' .. tostring(isDowned) .. ' for targetPlayerId=' .. tostring(targetPlayerId))
    
    -- Allow burial if player is dead OR downed
    if not (isDead or isDowned) then
        QBCore.Functions.Notify(src, 'Player is not dead.', 'error')
        print('[DEBUG] Player not dead: targetPlayerId=' .. tostring(targetPlayerId))
        return
    end

    -- Check payment
    if Player.Functions.RemoveMoney('cash', Config.BurialCost) then
        QBCore.Functions.Notify(src, 'Paid $1M for burial.', 'success')
        print('[DEBUG] Payment successful for src=' .. tostring(src))
        TriggerClientEvent('undertaker:playBurialAnimation', -1)

        -- Wipe inventory if enabled
        if Config.ClearInventory then
            exports.ox_inventory:ClearInventory(targetPlayerId)
            print('[DEBUG] Inventory wiped for targetPlayerId=' .. tostring(targetPlayerId))
        end

        -- Teleport to morgue (Death PED will handle revive)
        TriggerClientEvent('undertaker:teleportToMorgue', targetPlayerId)
        print('[DEBUG] Teleporting targetPlayerId=' .. tostring(targetPlayerId) .. ' to morgue')

        -- Start morgue timer
        SetTimeout(Config.MorgueTime * 1000, function()
            if QBCore.Functions.GetPlayer(targetPlayerId) then
                TriggerClientEvent('undertaker:releaseFromMorgue', targetPlayerId)
                print('[DEBUG] Released targetPlayerId=' .. tostring(targetPlayerId) .. ' from morgue')
            end
        end)
    else
        QBCore.Functions.Notify(src, 'Not enough cash.', 'error')
        print('[DEBUG] Not enough cash for src=' .. tostring(src))
    end
end)