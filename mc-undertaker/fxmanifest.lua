fx_version 'cerulean'
game 'gta5'

author 'mc-scripts'
description 'QBCore Undertaker Plugin for Burying Players'
version '1.0.0'

shared_scripts {
    'config.lua',
    'shared.lua'
}

client_scripts {
    'client.lua'
}

server_scripts {
    'server.lua'
}

dependencies {
    'qb-core',
    'ox_inventory',
    'qb-smallresources',
    'qb-ambulancejob'
}