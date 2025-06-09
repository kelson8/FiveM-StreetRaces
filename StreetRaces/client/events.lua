
-- Adapted from functions.lua in kc_menu
-- TODO Change this, I want to test it first.
-- Play arena war music
RegisterNetEvent('StreetRaces:start_music')
AddEventHandler('StreetRaces:start_music', function ()
    local arenaWarMusic = "AW_LOBBY_MUSIC_START"
    TriggerMusicEvent(arenaWarMusic)
end)

-- Stop music

RegisterNetEvent('StreetRaces:stop_music')
AddEventHandler('StreetRaces:stop_music', function ()
    TriggerMusicEvent("MP_MC_CMH_IAA_FINALE_START")
end)


