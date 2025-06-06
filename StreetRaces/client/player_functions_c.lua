
local player = GetPlayerPed(-1)

-- https://docs.fivem.net/docs/scripting-manual/working-with-events/listening-for-events/

-- TODO Figure out how to do this and teleport the players vehicle with them when moving routing buckets.

-- Hmm, if I can figure out teleporting the vehicle in kc_lobby, I should be able to finish this part.
-- Make this teleport the player into the no population lobby, optionally bring their car if they have one.
RegisterNetEvent("StreetRaces:vehicleCheck_cl")
AddEventHandler("StreetRaces:vehicleCheck_cl", function()
    if IsPedInAnyVehicle(ped, false) then
        local vehicle = GetVehiclePedIsIn(ped, false)
            return vehicle
            -- return true
        else 
            return false
        end
end)



function GetPlayerVehicle()
-- This doesn't work server side.
    if IsPedInAnyVehicle(ped, false) then
    local vehicle = GetVehiclePedIsIn(ped, false)
        return true
    else 
        return false
    end
end

