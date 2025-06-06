-- Saved player data and file

local playersData = nil
local playersDataFile = GetResourcePath("StreetRaces") .. "./data/StreetRaces_saveData.txt"
-- Test this later (If the resource is ever renamed, the above would no longer work):
-- local playersDataFile = GetResourcePath(GetCurrentResourceName()) .. "./data/StreetRaces_saveData.txt"

-- https://forum.cfx.re/t/howto-fivem-lua-scripting-complete-not-yet-guide/1467797

-- Custom for json test by kelson8
-- Attempt to get the value from checkpoints, try and figure out how to output each value one by one, possibly use a loop.
-- I forgot to add the ./ to the data folder, it outputs now!!!!
-- https://forum.cfx.re/t/how-to-json-with-fivem/237542
RegisterCommand("jsonr", function()
    -- local loaded_data = LoadResourceFile(GetCurrentResourceName(), "./data/" .. "StreetRaces_saveData" .. ".txt")
    local loaded_data = LoadResourceFile(GetCurrentResourceName(), "./data/StreetRaces_saveData.txt")
    local file_data = json.decode(loaded_data)
    -- print(loaded_data) -- This works, don't get rid of it.

    -- local file_data = {}
    -- local file_data = json.encode(loaded_data)
    -- notify(file_data)
end, false)

-- RegisterCommand("loadplr", function()
--     loadPlayerData(source)
-- end)

-- End custom functions
-----

-- Helper function for getting player money
function getMoney(source)
    -- Add framework API's here (return large number by default)
    return 1000000
end

-- Helper function for removing player money
function removeMoney(source, amount)
    -- Add framework API's here
end

-- Helper function for adding player money
function addMoney(source, amount)
    -- Add framework API's here
end

-- Helper function for getting player name
function getName(source)
    -- Add framework API's here
    return GetPlayerName(source)
end

-- Helper function for notifying players
-- Todo Set this to toggle between my custom notification and the 
-- chat notification depending on which one is set in the config.
function notifyPlayer(source, msg)
    -- Add custom notification here (use chat by default)
    -- TriggerClientEvent('chatMessage', source, "[StreetRaces]", {255, 0, 0}, msg)
    -- This works! My first time doing client to server events.
    TriggerClientEvent("StreetRaces:notifyClient", source, msg)
end



-- Helper function for loading saved player data
function loadPlayerData(source)
    -- Load data from file if not already initialized
    if playersData == nil then
        playersData = {}
        local file = io.open(playersDataFile, "r")
        if file then
            local contents = file:read("*a")
            playersData = json.decode(contents);
            io.close(file)
        end
    end

    -- Get player steamID from source and use as key to get player data
    local playerId = string.sub(GetPlayerIdentifier(source, 0), 7, -1)
    local playerData = playersData[playerId]

    -- Return saved player data
    if playerData == nil then
        playerData = {}
    end
    return playerData
end

-- Helper function for saving player data
function savePlayerData(source, data)
    -- Load data from file if not already initialized
    if playersData == nil then
        playersData = {}
        local file = io.open(playersDataFile, "r")
        if file then
            local contents = file:read("*a")
            playersData = json.decode(contents);
            io.close(file)
        end
    end

    -- Get player steamID from source and use as key to save player data
    local playerId = string.sub(GetPlayerIdentifier(source, 0), 7, -1)
    playersData[playerId] = data

    -- Save file
    local file = io.open(playersDataFile, "w+")
    if file then
        local contents = json.encode(playersData)
        file:write(contents)
        io.close(file)
    end
end
