-- DEFINITIONS AND CONSTANTS
local RACE_STATE_NONE = 0
local RACE_STATE_JOINED = 1
local RACE_STATE_RACING = 2
local RACE_STATE_RECORDING = 3
-- Add this to remove the waypoint recording when a race is loaded.
-- I need to add a seperate edit race option to the menu.
local RACE_STATE_LOADED = 4
local RACE_CHECKPOINT_TYPE = 45
local RACE_CHECKPOINT_FINISH_TYPE = 9


function notify(msg)
    SetNotificationTextEntry("STRING")
    AddTextComponentString(msg)
    DrawNotification(true, false)
end

-- https://docs.fivem.net/docs/scripting-manual/working-with-events/listening-for-events/
-- https://docs.fivem.net/docs/scripting-manual/working-with-events/triggering-events/

-- I fixed this by moving all the functions from races_cl into here, it works great with my gui now.
-- I wonder if I could setup loading the list of strings from json into a ScaleformList

-- The unload event and the remove events don't seem to delete the yellow markers off the map, try to fix that.
-- Fixed above on 3-28-2024 @ 5:35AM



---
-- https://github.com/0324bence/Fivem-json-handler/blob/main/json_handler/server.lua
-- function GetJsonTest(filename, itemname)
--     local loaded_data = LoadResourceFile(GetCurrentResourceName(), "data/" .. filename .. ".json")
--     local file_data = json.decode(loaded_data or "{}")
--     return file_data[itemname]
-- end

function sendMessage(source, msg)
    TriggerEvent('chat:addMessage', source, {
        args = { msg, },
    })
end

---

RegisterNetEvent("StreetRaces:notifyClient")
AddEventHandler("StreetRaces:notifyClient",
    function(msg)
        SetNotificationTextEntry("STRING")
        AddTextComponentString(msg)
        DrawNotification(true, false)
    end)

-- Races and race status
local races = {}
local raceStatus = {
    state = RACE_STATE_NONE,
    index = 0,
    checkpoint = 0,
    currentLap = 0,
    totalLaps = 0,
    totalCheckpoints = 0,
    myPosition = 0,
    totalPlayers = 0,
    distanceTraveled = 0
}

-- Recorded checkpoints
local recordedCheckpoints = {}

-- Todo:
-- Add a edit race option to the menu


function CreateMenu()
    local txd = CreateRuntimeTxd("scaleformui")
    -- These weren't in use.
    local duiPanel = CreateDui("https://i.imgur.com/mH0Y65C.gif", 288, 160)
    CreateRuntimeTextureFromDuiHandle(txd, "sidepanel", GetDuiHandle(duiPanel))
    -- Original
    -- local duiBanner = CreateDui("https://i.imgur.com/3yrFYbF.gif", 288, 160)
    -- Anime gif background
    local duiBanner = CreateDui("https://i.pinimg.com/originals/a3/1d/7f/a31d7f5c20b885859e84ceea2d71d7b6.gif", 288, 160)
    CreateRuntimeTextureFromDuiHandle(txd, "menuBanner", GetDuiHandle(duiBanner))

    -- Initalize the menu
    local mainMenu = UIMenu.New("Main Menu", "Street races GUI", 50, 50, true, "scaleformui", "menubanner", true)
    mainMenu:MaxItemsOnScreen(7)
    mainMenu:AnimationEnabled(false)
    mainMenu:BuildingAnimation(MenuBuildingAnimation.NONE)
    mainMenu:ScrollingType(MenuScrollingType.CLASSIC)
    mainMenu:CounterColor(SColor.HUD_YELLOW)
    -- MouseSettings(enableMouseControls, enableEdge, isWheelEnabled, resetCursorOnOpen, leftClickSelect)
    mainMenu:MouseSettings(false, false, true, false, true)

    -- Basic race gui, most functions are currently working.
    -- Some of these functions require parameters, I will
    -- need to figure out how to pass a list of the parameters
    -- stored in the json and output it to a listbox on here.
    local vehicleMenuItem = UIMenuItem.New("Race Menu", "Street races")
    mainMenu:AddItem(vehicleMenuItem)
    local vehicleMenu = UIMenu.New("Race Menu", "Street races", 50, 50, true, nil, nil, true)

    -- Not implemented yet. {Doesn't work}
    local startRaceItem = UIMenuItem.New("Start race", "Start a loaded race.")
    vehicleMenu:AddItem(startRaceItem)

    -- local cancelRaceItem = UIMenuItem.New("Cancel race", "Cacnel the current race.")
    -- vehicleMenu:AddItem(cancelRaceItem)

    local createRaceItem = UIMenuItem.New("Create race", "Create a new race.")
    vehicleMenu:AddItem(createRaceItem)

    local deleteRaceItem = UIMenuItem.New("Delete race", "Leaves the current race.")
    vehicleMenu:AddItem(deleteRaceItem)

    local saveRaceItem = UIMenuItem.New("Save race", "Save a race.")
    vehicleMenu:AddItem(saveRaceItem)

    local loadRaceItem = UIMenuItem.New("Load race", "Load the selected race.")
    vehicleMenu:AddItem(loadRaceItem)

    -- Not implemented yet.
    local unloadRaceItem = UIMenuItem.New("Unload race", "Stop the current race from showing up.")
    vehicleMenu:AddItem(unloadRaceItem)

    local listRaceItem = UIMenuItem.New("List races", "Lists races stored in the file.")
    vehicleMenu:AddItem(listRaceItem)

    -- local leaveRaceItem = UIMenuItem.New("Leave race", "Leave the current race.")
    -- vehicleMenu:AddItem(leaveRaceItem)

    -- local totalLaps = UIMenuIte

    -- Will this work?
    -- listRaceItem.OnItemSelect = function(sender, item, index)
    --     if item == listRaceItem then
    --         TriggerServerEvent('StreetRaces:listRaces_sv')
    --         notify("Race list..")
    --     end
    -- end


    -- For some reason the IsWaypointActive check seems to work for the count down but the checkpoints don't load up.
    -- The recordedCheckpoints check is doing nothing
    startRaceItem.Activated = function(sender, item, index)
        if item == startRaceItem then
            -- Incomplete
            -- local amount = 0
            -- if amount then
            --     -- Get optional start delay argument and starting coordinates
            --     local startDelay = tonumber(args[3])
            --     startDelay = startDelay and startDelay*1000 or config_cl.joinDuration
            --
            --     local TotalLaps = tonumber(args[2])
            -- end

            -- Todo Set this to get user input from a list.
            -- local TotalLaps = ""


            -- Uncomment below when I want to work on this again.

            -- User input (Keyboard)
            -- local startDelay = KeyboardInput("Race start delay", "", 10) or config_cl.joinDuration
            -- local TotalLaps = KeyboardInput("Total laps", "", 10) or config_cl.totalLaps
            -- local amount = KeyboardInput("Money to set for winner", "", 10) or 200
            -- Disable KeyboardInput as a test.


            -- local amount = 200

            local amount = 0
            -- if TotalLaps ~= nil then
            -- if amount then   // GetPlayerPed(-1)
            local startCoords = GetEntityCoords(PlayerPedId())
            local startDelay = 5000         --config_cl.joinDuration
            -- local TotalLaps = 2 --config_cl.totalLaps
            local TotalLaps = config_cl.totalLaps


            if #recordedCheckpoints > 0 then
                -- Ok this is the problem, nothing below this is printing or doing anything
                -- It's something to do with recordedCheckpoints missing or something.
                -- notify("Debug line") -- Doesn't print with a race loaded in.

                -- Create race using custom checkpoints
                TriggerServerEvent('StreetRaces:createRace_sv', amount, startDelay, startCoords, TotalLaps,
                    recordedCheckpoints)

                -- For some reason the IsWaypointActive check seems to work fine.
            elseif IsWaypointActive() then
                -- Create race using waypoint as the only checkpoint

                --notify("Debug line")

                local waypointCoords = GetBlipInfoIdCoord(GetFirstBlipInfoId(8))

                local retval, nodeCoords = GetClosestVehicleNode(waypointCoords.x, waypointCoords.y, waypointCoords.z, 1)
                table.insert(recordedCheckpoints, { blip = nil, coords = nodeCoords })
                TriggerServerEvent('StreetRaces:createRace_sv', amount, startDelay, startCoords, recordedCheckpoints, 10)
                -- end

                -- Set state to none to cleanup recording blips while waiting to join
                raceStatus.state = RACE_STATE_NONE
                -- raceStatus.state = RACE_STATE_RACING
            end
        end
    end

    -- This one doesn't seem to do anything either.
    -- cancelRaceItem.Activated = function(sender, item, index)
    --     if item == cancelRaceItem then
    --         TriggerServerEvent('StreetRaces:cancelRace_sv')
    --     end
    -- end

    -- I fixed this by removing the example text/making it blank
    -- TODO Make this ask for confirmation.
    -- Todo make this get the data from the json file and list it off, instead of needing keyboard input
    deleteRaceItem.Activated = function(sender, item, index)
        if item == deleteRaceItem then
            -- This one needs to get user input.
            local result = KeyboardInput("Delete Race", "", 20)

            if result ~= nil then
                TriggerServerEvent('StreetRaces:deleteRace_sv', result)
            end
        end
    end

    -- Save the race results, uses keyboard input
    saveRaceItem.Activated = function(sender, item, index)
        if item == saveRaceItem then
            local result = KeyboardInput("Save Race", "", 20)
            if result ~= nil and #recordedCheckpoints > 0 then
                TriggerServerEvent('StreetRaces:saveRace_sv', result, recordedCheckpoints)
            end
        end
    end

    -- Todo make this get the data from the json file and list it off, instead of needing keyboard input
    loadRaceItem.Activated = function(sender, item, index)
        if item == loadRaceItem then
            local raceName = KeyboardInput("Race to load", "", 20)
            -- TODO REVERT THIS!!! Temporary testing hard coded.
            -- local raceName = "Mayhem #1"

            -- TODO Change this
            TriggerServerEvent('StreetRaces:loadRace_sv', raceName)
            -- Move vehicle routing bucket test
            -- if IsPedInAnyVehicle(GetPlayerPed(-1), false) then
            --     local vehicle = GetVehiclePedIsIn(GetPlayerPed(-1), false)
            --     local netId = NetworkGetNetworkIdFromEntity(vehicle)
            --     local entityFromNetId = NetworkGetEntityFromNetworkId(netId)

            --     -- TODO Test this, it should bring the players vehicle with them when doing load race.
            --     -- This says invalid entity id, I wonder how to fix it.
            --     TriggerServerEvent('StreetRaces:moveVehicle_sv', entityFromNetId, 2)
            -- end
        end
    end

    -- Leave the current race, I added a confirmation box to this.
    -- Was this not in use? The unload race worked but this did nothing
    -- leaveRaceItem.Activated = function(sender, item, index)
    --     if item == leaveRaceItem then
    --     -- If player is part of a race, clean up map and send leave event to server
    --         if raceStatus.state == RACE_STATE_JOINED or raceStatus.state == RACE_STATE_RACING then

    --             -- Added confirmation to this, now leaving a race requires the user to input Y to confirm.
    --             local result = KeyboardInput("Confirm (Type Y to confirm)", "", 20)

    --             if result == "Y" or result == "y" then
    --                 cleanupRace()
    --                 TriggerServerEvent('StreetRaces:leaveRace_sv', raceStatus.index)
    --             end
    --         end
    --     end
    -- end

    -----
    -- List the races in a notification, probably not a good idea for a big list of them.
    -----
    listRaceItem.Activated = function(sender, item, index)
        if item == listRaceItem then
            TriggerServerEvent('StreetRaces:listRaces_sv')
            -- notify("Race list..")
        end
    end


    -----
    -- Create a race
    -- This one seems to be working now.
    -- A marker can be set with this using "E", instead of clicking on the map
    -- Well I made a confirm button for this so it shouldn't wipe the races without confirmation here.
    -----
    createRaceItem.Activated = function(sender, item, index)
        if item == createRaceItem then
            -- Added confirmation to this, now creating a race requires the user to input Y to confirm.
            local result = KeyboardInput("Confirm (Type Y to confirm)", "", 20)

            if result == "Y" or result == "y" then
                SetWaypointOff()
                cleanupRecording()
                raceStatus.state = RACE_STATE_RECORDING
                notify(
                "Record active: Set markers on the map for waypoints. Or press ~b~E~w~/~b~DPAD-Right~w~ to place them.")
            end
        end
    end

    -- Unload the race
    unloadRaceItem.Activated = function(sender, item, index)
        if item == unloadRaceItem then
            -- Added confirmation to this, now unloading a race requires the user to input Y to confirm.
            -- This only works if the user is in a race, recording or anything.
            -- If the state is none it won't do anything.
            if raceStatus.state ~= RACE_STATE_NONE then
                local result = KeyboardInput("Confirm (Type Y to confirm)", "", 20)

                if result == "Y" or result == "y" then
                    -- This is the event that is supposed to trigger
                    -- This is an old event
                    -- TriggerEvent("StreetRaces:removeRace_cl", raceStatus.index)
                    

                    -- This seems to work fine now for unloading races when in RACE_STATE_LOADED and RACE_STATE_RECORDING now.
                    TriggerEvent("StreetRaces:unloadRace_cl", raceStatus.index)

                    -- TriggerServerEvent('StreetRaces:leaveRace_sv', raceStatus.index)

                    -- cleanupRace()

                    -- What is the point of this event? It doesn't do anything.
                    -- TriggerServerEvent('StreetRaces:unloadRace_sv', raceStatus.index)
                end
            end
        end
    end

    vehicleMenuItem.Activated = function(menu, item)
        menu:SwitchTo(vehicleMenu, 1, true)
    end

    -- Making the menu visible.
    mainMenu:Visible(true)
end

-----
-- Draw the menu
-- TODO Add config for this part
-----
Citizen.CreateThread(function()
    while true do
        Wait(0)
        -- Keyboard
        -- F5 key, draw the main menu
        if IsControlJustPressed(0, 166) and not MenuHandler:IsAnyMenuOpen() and GetLastInputMethod(0) then
            CreateMenu()
        end

        -- TODO This sometimes activates and sometimes doesn't, try to fix that.
        -- Controller
        -- RB + DPAD UP
        if IsControlJustPressed(1, 44) and IsControlJustPressed(1, 172)
            and not MenuHandler:IsAnyMenuOpen()
            and not GetLastInputMethod(0) then
            CreateMenu()
        end
    end
end)


-- This unload event doesn't seem to delete the yellow markers off the map, try to fix that.
-- Is this needed? The remove race function seems to work fine for this.
RegisterNetEvent("StreetRaces:unloadRace_cl")
AddEventHandler("StreetRaces:unloadRace_cl", function(index)
    if raceStatus.state == RACE_STATE_JOINED
        or raceStatus.state == RACE_STATE_RACING
        or raceStatus.state == RACE_STATE_LOADED
        -- Oh no wonder this wouldn't let me remove these when recording.
        -- I actually had it excluded here.. Oops...
        -- I only found out because creating a race would wipe the markers.
        or raceStatus.state == RACE_STATE_RECORDING then
        raceStatus.index = index
        raceStatus.state = RACE_STATE_NONE

        -- This.. Started working? I don't know what happened.
        -- notify("Test.")
        cleanupRecording()
        cleanupRace()

        -- for index1, checkpoint in pairs(recordedCheckpoints) do
        --     checkpoint.blip = AddBlipForCoord(checkpoint.coords.x, checkpoint.coords.y, checkpoint.coords.z)
        --     RemoveBlip(checkpoint.blip)
        --     -- SetBlipColour(checkpoint.blip, config_cl.checkpointBlipColor)
        --     -- SetBlipAsShortRange(checkpoint.blip, true)
        --     -- ShowNumberOnBlip(checkpoint.blip, index1)
        -- end
        SetWaypointOff()
    end
end)

-- Test unloadRace function in this file

-- Copied below code from races_cl, I disabled the races_cl in the fxmanifest so I could test this out

-----

-----
-- Client event for when a race is created
-----
RegisterNetEvent("StreetRaces:createRace_cl")
AddEventHandler("StreetRaces:createRace_cl", function(index, amount, startDelay, startCoords, TotalLaps, checkpoints)
    -- Create race struct and add to array
    local race = {
        laps = TotalLaps,
        amount = amount,
        started = false,
        startTime = GetGameTimer() + startDelay,
        startCoords = startCoords,
        checkpoints = checkpoints
    }

    raceStatus.totalLaps = laps
    raceStatus.totalCheckpoints = 0
    races[index] = race
end)

-----
-- Client event for loading a race with no marker placing
-- This seems to work now for unloading the race also.
-----
RegisterNetEvent("StreetRaces:loadRace_cl")
AddEventHandler("StreetRaces:loadRace_cl", function(checkpoints)
    -- Cleanup recording, save checkpoints and set state to recording
    cleanupRecording()
    recordedCheckpoints = checkpoints

    -- Random index number for this, above 0
    -- raceStatus.index = 1
    raceStatus.state = RACE_STATE_LOADED
    raceStatus.currentLap = 1
    -- Add map blips
    for index, checkpoint in pairs(recordedCheckpoints) do
        checkpoint.blip = AddBlipForCoord(checkpoint.coords.x, checkpoint.coords.y, checkpoint.coords.z)
        SetBlipColour(checkpoint.blip, config_cl.checkpointBlipColor)
        SetBlipAsShortRange(checkpoint.blip, true)
        ShowNumberOnBlip(checkpoint.blip, index)
    end

    -- Clear waypoint and add route for first checkpoint blip
    SetWaypointOff()
    SetBlipRoute(checkpoints[1].blip, true)
    SetBlipRouteColour(checkpoints[1].blip, config_cl.checkpointBlipColor)
end)


-----
-- Load a race in recording mode, for now only active when creating races
-- TODO Add an edit mode for existing races.
-- This seems to work fine now and can be unloaded.
-----
RegisterNetEvent('StreetRaces:loadRecordingRace_cl')
AddEventHandler('StreetRaces:loadRecordingRace_cl', function()
    -- Cleanup recording, save checkpoints and set state to recording
    cleanupRecording()
    recordedCheckpoints = checkpoints

    raceStatus.state = RACE_STATE_RECORDING
    raceStatus.currentLap = 1
    -- Add map blips
    for index, checkpoint in pairs(recordedCheckpoints) do
        checkpoint.blip = AddBlipForCoord(checkpoint.coords.x, checkpoint.coords.y, checkpoint.coords.z)
        SetBlipColour(checkpoint.blip, config_cl.checkpointBlipColor)
        SetBlipAsShortRange(checkpoint.blip, true)
        ShowNumberOnBlip(checkpoint.blip, index)
    end

    -- Clear waypoint and add route for first checkpoint blip
    SetWaypointOff()
    SetBlipRoute(checkpoints[1].blip, true)
    SetBlipRouteColour(checkpoints[1].blip, config_cl.checkpointBlipColor)

end)

-----
-- Client event for when a race is joined
-----
RegisterNetEvent("StreetRaces:joinedRace_cl")
AddEventHandler("StreetRaces:joinedRace_cl", function(index)
    -- Set index and state to joined
    raceStatus.index = index
    raceStatus.state = RACE_STATE_JOINED
    raceStatus.currentLap = 1
    -- Add map blips
    local race = races[index]
    local checkpoints = race.checkpoints
    for index, checkpoint in pairs(checkpoints) do
        checkpoint.blip = AddBlipForCoord(checkpoint.coords.x, checkpoint.coords.y, checkpoint.coords.z)
        SetBlipColour(checkpoint.blip, config_cl.checkpointBlipColor)
        SetBlipAsShortRange(checkpoint.blip, true)
        ShowNumberOnBlip(checkpoint.blip, index)
    end

    -- Clear waypoint and add route for first checkpoint blip
    SetWaypointOff()
    SetBlipRoute(checkpoints[1].blip, true)
    SetBlipRouteColour(checkpoints[1].blip, config_cl.checkpointBlipColor)
end)

-----
-- Client event for when a race is removed
-- This seems to work fine now, more testing may be needed.
-- I added the index to the parameters in the menu item.
-- This seems to be what is nil now.
-----
RegisterNetEvent("StreetRaces:removeRace_cl")
AddEventHandler("StreetRaces:removeRace_cl", function(index)
    -- Check if index matches active race
    if index == raceStatus.index then
        -- Cleanup map blips and checkpoints
        cleanupRace()

        -- Reset racing state
        raceStatus.index = 0
        raceStatus.checkpoint = 0
        raceStatus.state = RACE_STATE_NONE
        raceStatus.currentLap = 0

        notify("Race ~b~unloaded~w~.")

    elseif index < raceStatus.index then
        -- Decrement raceStatus.index to match new index after removing race
        raceStatus.index = raceStatus.index - 1
    end

    -- Remove race from table
    -- TODO Is this needed? These values don't seem to be in use, at least the races one doesn't
    table.remove(races, index)
end)

-----
-- Client event for updated position
-----
RegisterNetEvent("StreetRaces:updatePos")
AddEventHandler("StreetRaces:updatePos", function(position, allPlayers)
    raceStatus.myPosition = position
    raceStatus.totalPlayers = allPlayers
end)



-----
-- Helper function to clean up race blips, checkpoints and status
-----
function cleanupRace()
    -- Cleanup active race
    if raceStatus.index ~= 0 then
        -- print("Race status index:" .. raceStatus.index)

        -- Cleanup map blips and checkpoints
        -- TODO Why is this nil now
        local race = races[raceStatus.index]
        -- print("Race table:" .. race)
        local checkpoints = race.checkpoints
        for _, checkpoint in pairs(checkpoints) do
            if checkpoint.blip then
                RemoveBlip(checkpoint.blip)
            end
            if checkpoint.checkpoint then
                DeleteCheckpoint(checkpoint.checkpoint)
            end
        end

        -- Set new waypoint to finish if racing or loaded
        -- if raceStatus.state == RACE_STATE_RACING then
        if raceStatus.state == RACE_STATE_RACING or raceStatus.state == RACE_STATE_LOADED then
            local lastCheckpoint = checkpoints[#checkpoints]
            SetNewWaypoint(lastCheckpoint.coords.x, lastCheckpoint.coords.y)
        end

        -- Unfreeze vehicle
        local vehicle = GetVehiclePedIsIn(GetPlayerPed(-1), false)
        FreezeEntityPosition(vehicle, false)
    end
end

-----
-- Helper function to clean up recording blips
-----
function cleanupRecording()
    -- Remove map blips and clear recorded checkpoints
    for _, checkpoint in pairs(recordedCheckpoints) do
        RemoveBlip(checkpoint.blip)
        checkpoint.blip = nil
    end
    recordedCheckpoints = {}
end

-----

-----
-- Position update thread
-----
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(100)
        -- When racing flag is set, update race positions.
        if raceStatus.state == RACE_STATE_RACING then
            newpos = GetEntityCoords(PlayerPedId())
            dist = GetDistanceBetweenCoords(oldpos.x, oldpos.y, oldpos.z, newpos.x, newpos.y, newpos.z, true)
            oldpos = newpos
            raceStatus.distanceTraveled = raceStatus.distanceTraveled + dist
            local value = raceStatus.totalCheckpoints + math.floor(raceStatus.distanceTraveled * 1.33) / 1000
            TriggerServerEvent('StreetRaces:updatecheckpoitcount_sv', raceStatus.index, value)
        end
    end
end)

-----
-- Checkpoint recording thread
-----
Citizen.CreateThread(function()
    -- Loop forever and record checkpoints every 100ms
    while true do
        Citizen.Wait(0)

        -- When recording flag is set, save checkpoints
        -- if raceStatus.state == RACE_STATE_RECORDING and not raceStatus.state == RACE_STATE_LOADED then
            if raceStatus.state == RACE_STATE_RECORDING then
            -- if raceStatus.state == RACE_STATE_RECORDING then
            -- Create new checkpoint when waypoint is set
            if IsWaypointActive() then
                -- Get closest vehicle node to waypoint coordinates and remove waypoint
                local waypointCoords = GetBlipInfoIdCoord(GetFirstBlipInfoId(8))
                local retval, coords = GetClosestVehicleNode(waypointCoords.x, waypointCoords.y, waypointCoords.z, 1)

                SetWaypointOff()

                -- Check if coordinates match any existing checkpoints
                for index, checkpoint in pairs(recordedCheckpoints) do
                    if GetDistanceBetweenCoords(coords.x, coords.y, coords.z, checkpoint.coords.x, checkpoint.coords.y, checkpoint.coords.z, false) < 1.0 then
                        -- Matches existing checkpoint, remove blip and checkpoint from table
                        RemoveBlip(checkpoint.blip)
                        table.remove(recordedCheckpoints, index)
                        coords = nil

                        -- Update existing checkpoint blips
                        for i = index, #recordedCheckpoints do
                            ShowNumberOnBlip(recordedCheckpoints[i].blip, i)
                        end
                        break
                    end
                end

                -- Add new checkpoint
                if (coords ~= nil) then
                    -- Add numbered checkpoint blip
                    local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
                    SetBlipColour(blip, config_cl.checkpointBlipColor)
                    SetBlipAsShortRange(blip, true)
                    ShowNumberOnBlip(blip, #recordedCheckpoints + 1)

                    -- Add checkpoint to array
                    table.insert(recordedCheckpoints, { blip = blip, coords = coords })
                end
            end
            if IsControlJustReleased(0, config_cl.markerKeybind) or IsControlJustReleased(1, config_cl.markerKeybind) then
                local player = GetPlayerPed(-1)
                local coords = GetEntityCoords(player)

                -- Add new checkpoint
                if (coords ~= nil) then
                    -- Add numbered checkpoint blip
                    local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
                    SetBlipColour(blip, config_cl.checkpointBlipColor)
                    SetBlipAsShortRange(blip, true)
                    ShowNumberOnBlip(blip, #recordedCheckpoints + 1)

                    -- Add checkpoint to array
                    table.insert(recordedCheckpoints, { blip = blip, coords = coords })
                end
                PlaySoundFrontend(-1, "RACE_PLACED", "HUD_AWARDS", true)
            end

            -- This just breaks the markers showing up when loading a race
            -- else
            -- -- Not recording, do cleanup
            -- cleanupRecording()
        end
    end
end)

-----
-- Load race thread
-- This new method works! I added a new event for this.
-----
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)

        -- and not raceStatus.state == RACE_STATE_RECORDING
        if raceStatus.state == RACE_STATE_LOADED then
            if IsWaypointActive() then
                local waypointCoords = GetBlipInfoIdCoord(GetFirstBlipInfoId(8))
                -- local _, coords = GetClosestVehicleNode(waypointCoords.x, waypointCoords.y, waypointCoords.z, 1)
                -- https://nativedb.dotindustries.dev/gta5/natives/0x240A18690AE96513?search=vehiclenode
                local _, coords = GetClosestVehicleNode(waypointCoords.x, waypointCoords.y, waypointCoords.z, 1,
                    1077936128, 0)
                -- local blip = AddBlipForCoord(coords.x, coords.y, coords.z)


                -- Check if coordinates match any existing checkpoints
                for index, checkpoint in pairs(recordedCheckpoints) do
                    if GetDistanceBetweenCoords(coords.x, coords.y, coords.z, checkpoint.coords.x, checkpoint.coords.y, checkpoint.coords.z, false) < 1.0 then
                        -- Matches existing checkpoint, remove blip and checkpoint from table
                        RemoveBlip(checkpoint.blip)
                        table.remove(recordedCheckpoints, index)
                        coords = nil

                        -- Update existing checkpoint blips
                        for i = index, #recordedCheckpoints do
                            ShowNumberOnBlip(recordedCheckpoints[i].blip, i)
                        end
                        break
                    end
                end


                -- -- SetNewWaypoint(coords.x, coords.y)
                -- SetBlipColour(blip, config_cl.checkpointBlipColor)

                -- for index, checkpoint in pairs(recordedCheckpoints) do
                --     checkpoint.blip = AddBlipForCoord(checkpoint.coords.x, checkpoint.coords.y, checkpoint.coords.z)
                --     SetBlipColour(checkpoint.blip, config_cl.checkpointBlipColor)
                --     SetBlipAsShortRange(checkpoint.blip, true)
                --     ShowNumberOnBlip(checkpoint.blip, index)
                -- end

                -- Clear waypoint and add route for first checkpoint blip
                SetWaypointOff()
                SetBlipRoute(checkpoints[1].blip, true)
                SetBlipRouteColour(checkpoints[1].blip, config_cl.checkpointBlipColor)

                -- end
                -- This breaks it
            -- else
                -- cleanupRace()
            end
        end
    end
end)

-- TODO Refactor this, move some of these into other threads or functions.
-- Main thread
Citizen.CreateThread(function()
    -- Loop forever and update every frame
    while true do
        Citizen.Wait(0)
        local checkpointType = RACE_CHECKPOINT_TYPE
        local nextCheckpoint

        -- Get player and check if they're in a vehicle
        -- local player = GetPlayerPed(-1)
        local player = PlayerPedId()
        if IsPedInAnyVehicle(player, false) then
            -- Get player position and vehicle
            local position = GetEntityCoords(player)
            local vehicle = GetVehiclePedIsIn(player, false)

            -- Player is racing
            if raceStatus.state == RACE_STATE_RACING then
                -- Initialize first checkpoint if not set
                local race = races[raceStatus.index]
                if raceStatus.checkpoint == 0 then
                    -- Increment to first checkpoint
                    raceStatus.checkpoint = 1
                    local checkpoint = race.checkpoints[raceStatus.checkpoint]

                    -- Create checkpoint when enabled
                    if config_cl.checkpointRadius > 0 then
                        checkpointType = RACE_CHECKPOINT_TYPE
                        checkpoint.checkpoint = CreateCheckpoint(checkpointType, checkpoint.coords.x, checkpoint.coords
                        .y, checkpoint.coords.z, 0, 0, 0, config_cl.checkpointRadius, 255, 255, 0, 127, 0)
                        SetCheckpointCylinderHeight(checkpoint.checkpoint, config_cl.checkpointHeight,
                            config_cl.checkpointHeight, config_cl.checkpointRadius)
                    end

                    -- Set blip route for navigation
                    SetBlipRoute(checkpoint.blip, true)
                    SetBlipRouteColour(checkpoint.blip, config_cl.checkpointBlipColor)
                else
                    -----
                    -- Check player distance from current checkpoint
                    -----
                    local checkpoint = race.checkpoints[raceStatus.checkpoint]
                    if GetDistanceBetweenCoords(position.x, position.y, position.z, checkpoint.coords.x, checkpoint.coords.y, 0, false) < config_cl.checkpointProximity then
                        -- Passed the checkpoint, delete map blip and checkpoint (only on last lap)
                        if raceStatus.currentLap == race.laps then
                            RemoveBlip(checkpoint.blip)
                        end
                        -- Delete the checkpoint marker in world
                        if config_cl.checkpointRadius > 0 then
                            DeleteCheckpoint(checkpoint.checkpoint)
                        end
                        -- update total checkpoints count and notify server
                        raceStatus.totalCheckpoints = raceStatus.totalCheckpoints + 1

                        -----
                        -- Check if at finish line
                        -----
                        if raceStatus.checkpoint == #(race.checkpoints) then
                            if raceStatus.currentLap == (race.laps) then
                                -- Play finish line sound
                                PlaySoundFrontend(-1, "ScreenFlash", "WastedSounds", true)

                                -- Send finish event to server
                                local currentTime = (GetGameTimer() - race.startTime)
                                TriggerServerEvent('StreetRaces:finishedRace_sv', raceStatus.index, currentTime)

                                -----
                                -- Reset state
                                -----
                                raceStatus.index = 0
                                raceStatus.state = RACE_STATE_NONE
                            else
                                -----
                                -- Add another lap
                                -----
                                PlaySoundFrontend(-1, "RACE_PLACED", "HUD_AWARDS", true)
                                raceStatus.currentLap = raceStatus.currentLap + 1
                                raceStatus.checkpoint = 1
                                local checkpoint = race.checkpoints[raceStatus.checkpoint]

                                -----
                                -- Create checkpoint when enabled
                                -----
                                if config_cl.checkpointRadius > 0 then
                                    checkpointType = RACE_CHECKPOINT_TYPE
                                    checkpoint.checkpoint = CreateCheckpoint(checkpointType, checkpoint.coords.x,
                                        checkpoint.coords.y, checkpoint.coords.z, 0, 0, 0, config_cl.checkpointRadius,
                                        255, 255, 0, 127, 0)
                                    SetCheckpointCylinderHeight(checkpoint.checkpoint, config_cl.checkpointHeight,
                                        config_cl.checkpointHeight, config_cl.checkpointRadius)
                                end

                                -----
                                -- Set blip route for navigation
                                -----
                                SetBlipRoute(checkpoint.blip, true)
                                SetBlipRouteColour(checkpoint.blip, config_cl.checkpointBlipColor)
                            end
                        else
                            -----
                            -- Play checkpoint sound
                            -----
                            PlaySoundFrontend(-1, "RACE_PLACED", "HUD_AWARDS", true)

                            -- Increment checkpoint counter and get next checkpoint
                            raceStatus.checkpoint = raceStatus.checkpoint + 1
                            nextCheckpoint = race.checkpoints[raceStatus.checkpoint]

                            -----
                            -- Create checkpoint when enabled
                            -----
                            if config_cl.checkpointRadius > 0 then
                                if raceStatus.currentLap == race.laps then
                                    if raceStatus.checkpoint == #race.checkpoints then
                                        checkpointType = RACE_CHECKPOINT_FINISH_TYPE
                                    else
                                        checkpointType = RACE_CHECKPOINT_TYPE
                                    end
                                else
                                    checkpointType = RACE_CHECKPOINT_TYPE
                                end

                                nextCheckpoint.checkpoint = CreateCheckpoint(checkpointType, nextCheckpoint.coords.x,
                                    nextCheckpoint.coords.y, nextCheckpoint.coords.z, 0, 0, 0, config_cl
                                .checkpointRadius, 255, 255, 0, 127, 0)
                                SetCheckpointCylinderHeight(nextCheckpoint.checkpoint, config_cl.checkpointHeight,
                                    config_cl.checkpointHeight, config_cl.checkpointRadius)
                            end

                            -----
                            -- Set blip route for navigation
                            -----
                            SetBlipRoute(nextCheckpoint.blip, true)
                            SetBlipRouteColour(nextCheckpoint.blip, config_cl.checkpointBlipColor)
                        end
                    end
                end

                -----
                -- Draw HUD when it's enabled
                -----
                if config_cl.hudEnabled then
                    -- Draw time and checkpoint HUD above minimap
                    local timeSeconds = (GetGameTimer() - race.startTime) / 1000.0
                    local timeMinutes = math.floor(timeSeconds / 60.0)
                    timeSeconds = timeSeconds - 60.0 * timeMinutes
                    Draw2DText(config_cl.hudPosition.x, config_cl.hudPosition.y,
                        ("~y~%02d:%06.3f"):format(timeMinutes, timeSeconds), 0.7)
                    local checkpoint = race.checkpoints[raceStatus.checkpoint]
                    local checkpointDist = math.floor(GetDistanceBetweenCoords(position.x, position.y, position.z,
                        checkpoint.coords.x, checkpoint.coords.y, 0, false))
                    Draw2DText(config_cl.hudPosition.x, config_cl.hudPosition.y + 0.04,
                        ("~y~CHECKPOINT %d/%d (%dm) | LAP %d/%d | POS %d/%d"):format(raceStatus.checkpoint,
                            #race.checkpoints, checkpointDist, raceStatus.currentLap, race.laps, raceStatus.myPosition,
                            raceStatus.totalPlayers), 0.5)
                end
                -----
                -- Player has joined a race
                -----
            elseif raceStatus.state == RACE_STATE_JOINED then
                -- Check countdown to race start
                local race = races[raceStatus.index]
                local currentTime = GetGameTimer()
                local count = race.startTime - currentTime

                if count <= 0 then
                    -- Race started, set racing state and unfreeze vehicle position
                    oldpos = GetEntityCoords(PlayerPedId())
                    newpos = GetEntityCoords(PlayerPedId())
                    raceStatus.distanceTraveled = 0
                    raceStatus.state = RACE_STATE_RACING
                    raceStatus.checkpoint = 0
                    raceStatus.currentLap = 1
                    FreezeEntityPosition(vehicle, false)
                elseif count <= config_cl.freezeDuration then
                    -- Display countdown text and freeze vehicle position
                    Draw2DText(0.5, 0.4, ("~y~%d"):format(math.ceil(count / 1000.0)), 3.0)
                    FreezeEntityPosition(vehicle, true)
                else
                    -- Draw 3D start time and join text
                    -- local temp, zCoord = GetGroundZFor_3dCoord(race.startCoords.x, race.startCoords.y, 9999.9, 1)
                    local temp, zCoord = GetGroundZFor_3dCoord(race.startCoords.x, race.startCoords.y, 9999.9, true)
                    Draw3DText(race.startCoords.x, race.startCoords.y, zCoord + 1.0,
                        ("Race for ~g~$%d~w~ starting in ~y~%d~w~s"):format(race.amount, math.ceil(count / 1000.0)))
                    Draw3DText(race.startCoords.x, race.startCoords.y, zCoord + 0.80, "Joined")
                end
                -----
                -- Player is not in a race
                -----
            else
                -- Loop through all races
                for index, race in pairs(races) do
                    -- Get current time and player proximity to start
                    local currentTime = GetGameTimer()
                    local proximity = GetDistanceBetweenCoords(position.x, position.y, position.z, race.startCoords.x,
                        race.startCoords.y, race.startCoords.z, true)

                    -- When in proximity and race hasn't started draw 3D text and prompt to join
                    if proximity < config_cl.joinProximity and currentTime < race.startTime then
                        -- Draw 3D text
                        local count = math.ceil((race.startTime - currentTime) / 1000.0)
                        local temp, zCoord = GetGroundZFor_3dCoord(race.startCoords.x, race.startCoords.y, 9999.9, false)
                        Draw3DText(race.startCoords.x, race.startCoords.y, zCoord + 1.0,
                            ("Race for ~g~$%d~w~ starting in ~y~%d~w~s"):format(race.amount, count))
                        -- Draw3DText(race.startCoords.x, race.startCoords.y, zCoord+0.80, "Press [~g~E~w~] to join")
                        Draw3DText(race.startCoords.x, race.startCoords.y, zCoord + 0.80,
                            "Press [~g~E/Right DPad~w~] to join")

                        -- Check if player enters the race and send join event to server
                        if IsControlJustReleased(1, config_cl.joinKeybind) then
                            TriggerServerEvent('StreetRaces:joinRace_sv', index)
                            break
                        end
                    end
                end
            end
        end
    end
end)
