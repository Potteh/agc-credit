fx_version 'cerulean'
game 'gta5'
lua54 'yes'
author 'AGC'
description 'QBCore credit score and credit card system'
version '1.0.0'

shared_scripts { 'config.lua' }
client_scripts { 'client/main.lua' }
server_scripts {
    'server/schema.lua', '@oxmysql/lib/MySQL.lua', 'server/main.lua' }
ui_page 'html/index.html'
files { 'html/index.html', 'html/app.js', 'html/style.css' }

dependency 'qb-core'
dependency 'oxmysql'
