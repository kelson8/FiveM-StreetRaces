fx_version 'cerulean'
game 'gta5'
lua54 'yes'

-- This requires ScaleformUI.
dependencies {
    'ScaleformUI_Lua',
    -- 'kc_util'
}

files {
	'data/StreetRaces_saveData.txt',
}

client_scripts {
    '@ScaleformUI_Lua/ScaleformUI.lua',
    "config.lua",
    -- "races_cl.lua",
    "race_gui.lua",
}

server_scripts {
    "config.lua",
    "port_sv.lua",
    "races_sv.lua",
}
