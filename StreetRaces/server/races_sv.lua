---@diagnostic disable: param-type-mismatch

-----
-- Server side array of active races
-----
local races = {}

-----
-- Cleanup thread
-----
Citizen.CreateThread(function()
    -- Loop forever and check status every 100ms
    while true do
        Citizen.Wait(100)

        -- Check active races and remove any that become inactive
        for index, race in pairs(races) do
            -- Get time and players in race
            local time = GetGameTimer()
            local players = race.players

            -- Check start time and player count
            if (time > race.startTime) and (#players == 0) then
                -- Race past start time with no players, remove race and send event to all clients
                table.remove(races, index)
                TriggerClientEvent("StreetRaces:removeRace_cl", -1, index)
                -- Check if race has finished and expired
            elseif (race.finishTime ~= 0) and (time > race.finishTime + race.finishTimeout) then
                -- Did not finish, notify players still racing
                for _, player in pairs(players) do
                    notifyPlayer(player, "DNF (timeout)")
                end

                -- Remove race and send event to all clients
                table.remove(races, index)
                TriggerClientEvent("StreetRaces:removeRace_cl", -1, index)
            end
        end
    end
end)

-- TODO Test this in the race resouce
-- RegisterNetEvent("StreetRaces:setEntityRtr")
-- AddEventHandler("StreetRaces:setEntityRtr", function(entityId, routingBucket)
--     -- local NetId = NetworkGetEntityFromNetworkId(tonumber(args[1]))
--     local netId = NetworkGetEntityFromNetworkId(entityId)
--     -- local routingBucket = tonumber(args[2])

--     -- if args[1] and args[2] ~= nil then
--         SetEntityRoutingBucket(netId, routingBucket)
--         sendMessage(source, ("You have set the routing bucket of %s to %s"):format(netId, routingBucket))
--     -- end
-- end)

-----
-- Server event for moving player and vehicle to routing bucket
-- TODO Set this one up.
-----
RegisterNetEvent("StreetRaces:moveVehicle_sv")
AddEventHandler("StreetRaces:moveVehicle_sv", function(vehicle, routingBucket)
    SetEntityRoutingBucket(vehicle, routingBucket)
end)

-----
-- Server event for creating a race
-----
RegisterNetEvent("StreetRaces:createRace_sv")
AddEventHandler("StreetRaces:createRace_sv",
    function(amount, startDelay, startCoords, TotalLaps, checkpoints, finishTimeout)
        -- Add fields to race struct and add to races array
        local race = {
            laps = TotalLaps,
            owner = source,
            amount = amount,
            startTime = GetGameTimer() + startDelay,
            startCoords = startCoords,
            checkpoints = checkpoints,
            finishTimeout = config_sv.finishTimeout,
            players = {},
            prize = 0,
            finishTime = 0,
            playersCheckpoints = {},
            totalPlayers = 0
        }
        table.insert(races, race)

        -- Send race data to all clients
        local index = #races
        if IsPlayerAceAllowed(source, "StreetRaces.create_race") then
            TriggerClientEvent("StreetRaces:createRace_cl", -1, index, amount, startDelay, startCoords, TotalLaps,
                checkpoints)
        else
            notifyPlayer(source, "You do not have permission to create a race.")
        end
    end)

-----
-- Server event for canceling a race
-----
RegisterNetEvent("StreetRaces:cancelRace_sv")
AddEventHandler("StreetRaces:cancelRace_sv", function()
    if IsPlayerAceAllowed(source, "StreetRaces.cancel_race") then
        -- Iterate through races
        for index, race in pairs(races) do
            -- Find if source player owns a race that hasn't started
            local time = GetGameTimer()
            if source == race.owner and time < race.startTime then
                -- Send notification and refund money for all entered players
                for _, player in pairs(race.players) do
                    -- Refund money to player and remove from prize pool
                    addMoney(player, race.amount)
                    race.prize = race.prize - race.amount

                    -- Notify player race has been canceled
                    local msg = "Race canceled"
                    notifyPlayer(player, msg)
                end

                -- Remove race from table and send client event
                table.remove(races, index)
                TriggerClientEvent("StreetRaces:removeRace_cl", -1, index)
            end
        end
    else
        notifyPlayer(source, "You do not have permission to cancel a race.")
    end
end)

-----
-- Server event for joining a race
-----
RegisterNetEvent("StreetRaces:joinRace_sv")
AddEventHandler("StreetRaces:joinRace_sv", function(index)
    -- Validate and deduct player money
    local race = races[index]
    local amount = race.amount
    local laps = race.laps
    local playerMoney = getMoney(source)
    if playerMoney >= amount then
        -- Deduct money from player and add to prize pool
        removeMoney(source, amount)
        race.prize = race.prize + amount

        -- Add player to race and send join event back to client
        table.insert(races[index].players, source)
        races[index].playersCheckpoints[source] = 0
        races[index].totalPlayers = races[index].totalPlayers + 1
        TriggerClientEvent("StreetRaces:joinedRace_cl", source, index)
    else
        -- Insufficient money, send notification back to client
        local msg = "Insuffient funds to join race"
        notifyPlayer(source, msg)
    end
end)

-----
-- Server event for leaving a race
-----
RegisterNetEvent("StreetRaces:leaveRace_sv")
AddEventHandler("StreetRaces:leaveRace_sv", function(index)
    -- Validate player is part of the race
    local race = races[index]
    local players = race.players
    for index, player in pairs(players) do
        if source == player then
            -- Remove player from race and break
            table.remove(players, index)
            break
        end
    end
end)

-----
-- Server event for finishing a race
-----
RegisterNetEvent("StreetRaces:finishedRace_sv")
AddEventHandler("StreetRaces:finishedRace_sv", function(index, time)
    -- Check player was part of the race
    local race = races[index]
    local players = race.players
    for index, player in pairs(players) do
        if source == player then
            -- Calculate finish time
            local time = GetGameTimer()
            local timeSeconds = (time - race.startTime) / 1000.0
            local timeMinutes = math.floor(timeSeconds / 60.0)
            timeSeconds = timeSeconds - 60.0 * timeMinutes

            -- If race has not finished already
            if race.finishTime == 0 then
                -- Winner, set finish time and award prize money
                race.finishTime = time
                addMoney(source, race.prize)

                -- Send winner notification to players
                for _, pSource in pairs(players) do
                    if pSource == source then
                        local msg = ("You won [%02d:%06.3f]"):format(timeMinutes, timeSeconds)
                        notifyPlayer(pSource, msg)
                        -- Set the player back to the normal routing bucket.
                        if config_cl.noPedLobby then
                            -- TODO Make this work with my new config.
                            
                            SetPlayerRoutingBucket(source, 0)
                        end
                        -- TODO Set vehicle back to normal routing bucket
                    elseif config_sv.notifyOfWinner then
                        local msg = ("%s won [%02d:%06.3f]"):format(getName(source), timeMinutes, timeSeconds)
                        -- Stop the music playing
                        TriggerClientEvent("StreetRaces:stop_music", source)
                        -- 

                        notifyPlayer(pSource, msg)
                    end
                end
            else
                -- Loser, send notification to only the player
                local msg = ("You lost [%02d:%06.3f]"):format(timeMinutes, timeSeconds)
                notifyPlayer(source, msg)
                -- Set the player back to the normal routing bucket.
                -- TODO Set vehicle back to normal routing bucket
                if config_cl.noPedLobby then
                    SetPlayerRoutingBucket(source, 0)
                end
            end

            -- Remove player form list and break
            table.remove(players, index)
            break
        end
    end
end)

-----
-- Server event for saving recorded checkpoints as a race
-----
RegisterNetEvent("StreetRaces:saveRace_sv")
AddEventHandler("StreetRaces:saveRace_sv", function(name, checkpoints)
    if IsPlayerAceAllowed(source, "StreetRaces.create_race") then
        -- Cleanup data so it can be serialized
        for _, checkpoint in pairs(checkpoints) do
            checkpoint.blip = nil
            checkpoint.coords = { x = checkpoint.coords.x, y = checkpoint.coords.y, z = checkpoint.coords.z }
        end

        -- Try to make this save to a json file with a race name.
        -- Something like this:
        -- MyRace1: points {
        -- 1: {X: 22, Y: 22, Z:22}}
        -- Get saved player races, add race and save
        local playerRaces = loadPlayerData(source)
        playerRaces[name] = checkpoints
        savePlayerData(source, playerRaces)

        -- Send notification to player
        local msg = "Saved " .. name
        notifyPlayer(source, msg)
    else
        notifyPlayer(source, "You do not have permission to save a race.")
    end
end)

-----
-- Server event for deleting recorded race
-----
RegisterNetEvent("StreetRaces:deleteRace_sv")
AddEventHandler("StreetRaces:deleteRace_sv", function(name)
    if IsPlayerAceAllowed(source, "StreetRaces.delete_race") then
        -- Get saved player races
        local playerRaces = loadPlayerData(source)

        -- Check if race with name exists
        if playerRaces[name] ~= nil then
            -- Delete race and save data
            playerRaces[name] = nil
            savePlayerData(source, playerRaces)

            -- Send notification to player
            local msg = "Deleted " .. name
            notifyPlayer(source, msg)
        else
            local msg = "No race found with name " .. name
            notifyPlayer(source, msg)
        end
    else
        notifyPlayer(source, "You do not have permission to delete a race.")
    end
end)

-----
-- Server event for listing recorded races
-----
RegisterNetEvent("StreetRaces:listRaces_sv")
AddEventHandler("StreetRaces:listRaces_sv", function()
    -- Get saved player races and iterate through saved races
    local msg = "Saved races: "
    local count = 0
    local playerRaces = loadPlayerData(source)
    for name, race in pairs(playerRaces) do
        msg = msg .. name .. ", "
        count = count + 1
    end

    -- Fix string formatting
    if count > 0 then
        msg = string.sub(msg, 1, -3)
    end

    -- Send notification to player with listing
    notifyPlayer(source, msg)
end)

-----
-- Server event for loaded recorded race
-----
RegisterNetEvent("StreetRaces:loadRace_sv")
AddEventHandler("StreetRaces:loadRace_sv", function(name)
    -- Get saved player races and load race
    local playerRaces = loadPlayerData(source)
    local race = playerRaces[name]

    -- If race was found send it to the client
    if race ~= nil then

        -- TODO Add check for this, if it is RACE_RECORDING then run the other event.
        -- Send race data to client
        TriggerClientEvent("StreetRaces:loadRace_cl", source, race)
        -- TriggerClientEvent("StreetRaces:loadRecordingRace_cl'", source, race)

        -- New event for recording only:
        -- TriggerClientEvent('StreetRaces:loadRecordingRace_cl', source, race)

        -- Set the players routing bucket to 2, which has population disabled.
        -- TODO Bring players vehicle with them.
        -- if IsPedInAnyVehicle(source, false) then
        --     local vehicle = GetVehiclePedIsIn(source, false)
        --     SetEntityRoutingBucket(vehicle, 2)
        --     SetPlayerRoutingBucket(source, 2)
        -- else
        --     SetPlayerRoutingBucket(source, 2)
        -- end
        -- SetPlayerRoutingBucket(source, 2)

        -- TODO Test this config option later, I would like to keep this as a config option.
        if config_cl.noPedLobby then
            SetPlayerRoutingBucket(source, 2)
        end
        -- TODO Set vehicle back too routing bucket 2

        -- Send notification to player
        -- local msg = "Loaded " .. name
        -- notifyPlayer(source, msg)
    else
        local msg = "No race found with name " .. name
        notifyPlayer(source, msg)
    end
end)


-----
-- Server event for unloading race
-----
RegisterNetEvent("StreetRaces:unloadRace_sv")
AddEventHandler("StreetRaces:unloadRace_sv", function(name)
    -- Get saved player races and load race
    -- local playerRaces = loadPlayerData(source)
    -- local race = playerRaces[name]

    -- If race was found send it to the client
    -- if race ~= nil then
    -- Send race data to client
    -- TriggerClientEvent("StreetRaces:unloadRace_cl", source, race)

    -- Set players routing bucket back to normal.
    -- TODO Bring players vehicle with them.

    -- local ped = GetPlayerPed(source)
    -- -- This doesn't work server side.
    -- if IsPedInAnyVehicle(ped, false) then
    --     local vehicle = GetVehiclePedIsIn(ped, false)
    --     SetEntityRoutingBucket(vehicle, 0)
    --     SetPlayerRoutingBucket(source, 0)
    -- else
    --     SetPlayerRoutingBucket(source, 0)
    -- end

    if config_cl.noPedLobby then
        SetPlayerRoutingBucket(source, 0)
    end


    -- Send notification to player
    -- local msg = "Loaded " .. name
    -- notifyPlayer(source, msg)
    -- else
    --     local msg = "No race found with name " .. name
    --     notifyPlayer(source, msg)
    -- end
end)

-----
-- Server event for updating positions
-----
RegisterNetEvent("StreetRaces:updatecheckpoitcount_sv")
AddEventHandler("StreetRaces:updatecheckpoitcount_sv", function(index, amount)
    -- update the checkpoints value for player
    local race = races[index]
    race.playersCheckpoints[source] = amount

    -- Complile a list of positions and send back to client
    local counter = 0
    for k, v in spairs(race.playersCheckpoints, function(t, a, b) return t[b] < t[a] end) do
        counter = counter + 1
        local allPlayers = race.totalPlayers
        if k == source then
            local playerID = k
            local position = counter
            -- send position (counter) to player
            TriggerClientEvent("StreetRaces:updatePos", playerID, position, allPlayers)
        end
    end
end)

-----
-- Something to do with the value keys in here
-- Seems to only run here: StreetRaces:updatecheckpoitcount_sv
-- This is something to do with updating the positions in the above event.
-----
function spairs(t, order)
    -- collect the keys
    local keys = {}
    for k in pairs(t) do keys[#keys + 1] = k end

    -- if order function given, sort by it by passing the table and keys a, b,
    -- otherwise just sort the keys
    if order then
        table.sort(keys, function(a, b) return order(t, a, b) end)
    else
        table.sort(keys)
    end

    -- return the iterator function
    local i = 0
    return function()
        i = i + 1
        if keys[i] then
            return keys[i], t[keys[i]]
        end
    end
end
