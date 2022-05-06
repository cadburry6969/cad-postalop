fx_version "cerulean"
game "gta5"

description "Postal Op Job which uses qb-target & polyzone"
author "Cadburry#7547"
version "1.0.0"

server_script 'sv_postalop.lua'
client_script 'cl_postalop.lua'

files {
    'handling.meta',
}

data_file 'HANDLING_FILE' 'handling.meta'
