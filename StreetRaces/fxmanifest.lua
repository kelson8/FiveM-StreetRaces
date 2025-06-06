fx_version 'cerulean'
game 'gta5'
lua54 'yes'

-- This requires ScaleformUI.
dependencies {
    'ScaleformUI_Lua',
    -- 'kc_util'
}

files {
	-- 'data/StreetRaces_saveData.txt',
	'data/StreetRaces_saveData.json',
}

shared_scripts {
    'config/config.lua',
}

client_scripts {
    '@ScaleformUI_Lua/ScaleformUI.lua',
    -- "config.lua",
    -- I don't think this one is in use anymore? I'll remove it later
    -- "client/races_cl.lua",
    -- "race_gui.lua",
    "client/race_gui.lua",
}

server_scripts {
    -- "config.lua",
    -- "port_sv.lua",
    -- "races_sv.lua",
    "server/port_sv.lua",
    "server/races_sv.lua",
}
