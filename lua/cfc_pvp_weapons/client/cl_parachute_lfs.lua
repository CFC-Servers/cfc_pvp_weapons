-- Optional LFS integration.


local function trySetupLFS()
    -- Client settings.
    CreateClientConVar( "cfc_parachute_lfs_eject", 2, true, true, "Whether or not exiting mid-air LFS planes will eject you with a parachute.", 0, 2 )

    -- Replicated server preferences of client settings.
    CreateConVar( "cfc_parachute_lfs_eject_sv", 1, { FCVAR_ARCHIVE, FCVAR_REPLICATED }, "Whether or not exiting mid-air LFS planes will launch the player up with a parachute. Defines the default value for players.", 0, 1 )

    -- Replicated server settings.
    CreateConVar( "cfc_parachute_lfs_eject_height", 500, { FCVAR_REPLICATED, FCVAR_ARCHIVE }, "The minimum height above the ground a player must be to auto-equip a parachute when ejecting from an LFS.", 0, 50000 )
    CreateConVar( "cfc_parachute_lfs_eject_launch_force", 1100, { FCVAR_REPLICATED, FCVAR_ARCHIVE }, "The upwards force applied to players when they launch out of an LFS plane.", 0, 50000 )
    CreateConVar( "cfc_parachute_lfs_eject_launch_bias", 25, { FCVAR_REPLICATED, FCVAR_ARCHIVE }, "How many degrees the LFS eject launch should course-correct the player's trajectory to send them straight up, for if their plane is tilted.", 0, 90 )


    table.insert( CFC_Parachute.MenuToggleButtons, {
        TextOff = "LFS Auto-Parachute (Disabled)",
        TextOn = "LFS Auto-Parachute (Enabled)",
        ConVar = "cfc_parachute_lfs_eject",
        ConVarServerChoice = "2"
    } )
end


hook.Add( "CFC_Parachute_CheckOptionalDependencies", "CFC_Parachute_SetupLFS", function()
    if not simfphys or not simfphys.LFS then return end

    trySetupLFS()
end )
