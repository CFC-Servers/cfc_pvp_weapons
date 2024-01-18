-- Optional LFS integration.


local function trySetupLFS()
    -- Client settings.
    CreateClientConVar( "cfc_parachute_lfs_eject", 2, true, true, "Whether or not exiting mid-air LFS planes will eject you with a parachute.", 0, 2 )

    -- Replicated server preferences of client settings.
    CreateConVar( "cfc_parachute_lfs_eject_sv", 1, { FCVAR_ARCHIVE, FCVAR_REPLICATED }, "Whether or not exiting mid-air LFS planes will launch the player up with a parachute. Defines the default value for players.", 0, 1 )


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
