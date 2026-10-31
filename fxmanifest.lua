fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'Project07_FreeSpawn'
author 'Project07'
description 'Free spawn selector: cinematic text-only list with an aerial camera, no admin panel, Discord logs'
version '1.0.0'

dependencies { 'ox_lib', 'Project7H_Lib' }

shared_scripts {
    '@ox_lib/init.lua',
    '@Project7H_Lib/imports.lua',
    'config.lua',
}

client_script 'client/main.lua'

server_scripts {
    'sv_config.lua',
    'server/main.lua',
}

ui_page 'web/build/spawn.html'

files {
    'web/build/spawn.html',
    'web/build/assets/*',
}
