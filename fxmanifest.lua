fx_version "cerulean"
game "gta5"
lua54 'yes'

author "Cadburry"
description "Postal Op Job which uses qb-target & polyzone"
version "1.1"

shared_scripts {
    'config.lua',
}
server_script 'server.lua'
client_script 'client.lua'

files {
    'handling.meta',
}

data_file 'HANDLING_FILE' 'handling.meta'
