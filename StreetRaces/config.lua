-- CLIENT CONFIGURATION
config_cl = {
    totalLaps = 1,                      -- Default total number of laps if no input set.
    joinProximity = 25,                 -- Proximity to draw 3D text and join race
    joinKeybind = 51,                   -- Keybind to join race ("E" by default, D-PAD Right on Xbox controller)
	markerKeybind = 51,                 -- Keybind to set markers ("E" by default)
    joinDuration = 5000,               -- Duration in ms to allow players to join the race
    freezeDuration = 5000,              -- Duration in ms to freeze players and countdown start (set to 0 to disable)
    checkpointProximity = 25.0,         -- Proximity to trigger checkpoint in meters
    checkpointRadius = 25.0,            -- Radius of 3D checkpoints in meters (set to 0 to disable cylinder checkpoints)
    checkpointHeight = 10.0,            -- Height of 3D checkpoints in meters
    checkpointBlipColor = 5,            -- Color of checkpoint map blips and navigation (see SetBlipColour native reference)
    hudEnabled = true,                  -- Enable racing HUD with time and checkpoints
    hudPosition = vec(0.015, 0.625),     -- Screen position to draw racing HUD

    noPedLobby = false,                  -- If this is set to true this will switch the players over to routing 
                                         -- bucket 2 when a race is started and 0 when it ends.
                                         -- This doesn't bring the vehicle with the player currently.

}

-- SERVER CONFIGURATION
config_sv = {
    finishTimeout = 180000,             -- Timeout in ms for removing a race after winner finishes
    notifyOfWinner = true               -- Notify all players of the winner (false will only notify the winner)
}
