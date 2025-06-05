Config = {}

Config.EnableUndertaker = true -- Enable/disable plugin
Config.PedSpawnHours = { start = 0, finish = 24 } -- PED spawns 24/7 -- 10-2 for only late night timespawn   
Config.MorgueTime = 300 -- Time in morgue (seconds, 60 for testing 300 for 5mins )
Config.BurialCost = 1000000 -- Burial cost ($1M) DEFAULT
Config.ClearInventory = true -- Wipe inventory with ox_inventory
Config.Peds = { -- Table of undertaker PEDs
    { model = 'a_m_m_hillbilly_01', coords = vector4(-286.18, 2838.66, 53.95, 144.31) }, -- Paleto Bay Cemetery
    { model = 'a_m_m_hillbilly_01', coords = vector4(-1759.55, -262.26, 48.14, 147.4) } -- Vinewood Cemetery, Los Santos
}
Config.MorgueCoords = vector4(253.61, -1350.93, 24.54, 315.83) -- IAA Basement
Config.DeathPed = { -- Death PED in morgue
    model = 'u_m_m_jesus_01', -- jesus ped
    coords = vector4(250.55, -1347.37, 24.54, 48.24), -- Near morgue coords, slightly offset
    reviveTime = 5000 -- Time for revive animation (5 seconds)
}
Config.ReleaseCoords = vector4(-778.5, -3.28, 41.12, 207.49) -- Church