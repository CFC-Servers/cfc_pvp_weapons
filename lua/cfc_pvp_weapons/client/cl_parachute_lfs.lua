-- Optional LFS integration.


local function trySetupLFS()
    -- Client settings.
    CreateClientConVar( "cfc_parachute_lfs_auto_equip", 2, true, true, "Whether or not to auto-equip a parachute when ejecting from an LFS plane in the air.", 0, 2 )
    CreateClientConVar( "cfc_parachute_lfs_eject_launch", 2, true, true, "Whether or not to launch up high when ejecting from an LFS plane in the air. Useful for pulling off a Rendezook.", 0, 2 )

    -- Replicated server preferences of client settings.
    CreateConVar( "cfc_parachute_lfs_auto_equip_sv", 1, { FCVAR_ARCHIVE, FCVAR_REPLICATED }, "Whether or not to auto-equip a parachute when ejecting from an LFS plane in the air. Defines the default value for players.", 0, 1 )
    CreateConVar( "cfc_parachute_lfs_eject_launch_sv", 1, { FCVAR_ARCHIVE, FCVAR_REPLICATED }, "Whether or not to launch up high when ejecting from an LFS plane in the air. Useful for pulling off a Rendezook. Defines the default value for players.", 0, 1 )

    -- Replicated server settings.
    CreateConVar( "cfc_parachute_lfs_eject_height", 500, { FCVAR_REPLICATED, FCVAR_ARCHIVE }, "The minimum height above the ground a player must be to auto-equip a parachute when ejecting from an LFS.", 0, 50000 )
    CreateConVar( "cfc_parachute_lfs_eject_launch_force", 1100, { FCVAR_REPLICATED, FCVAR_ARCHIVE }, "The upwards force applied to players when they launch out of an LFS plane.", 0, 50000 )
    CreateConVar( "cfc_parachute_lfs_eject_launch_bias", 25, { FCVAR_REPLICATED, FCVAR_ARCHIVE }, "How many degrees the LFS eject launch should course-correct the player's trajectory to send them straight up, for if their plane is tilted.", 0, 90 )
    CreateConVar( "cfc_parachute_lfs_eject_stability_time", 5, { FCVAR_REPLICATED, FCVAR_ARCHIVE }, "How many seconds a player is immune to parachute instability when they launch out of an LFS plane.", 0, 50000 )
    CreateConVar( "cfc_parachute_lfs_enter_radius", 800, { FCVAR_REPLICATED, FCVAR_ARCHIVE }, "How close a player must be to enter an LFS if they are in a parachute and regular use detection fails. Makes it easier to get inside of an LFS for performing a Rendezook.", 0, 50000 )


    table.insert( CFC_Parachute.MenuToggleButtons, {
        TextOff = "LFS Auto-Parachute (Disabled)",
        TextOn = "LFS Auto-Parachute (Enabled)",
        ConVar = "cfc_parachute_lfs_auto_equip",
        ConVarServerChoice = "2"
    } )

    table.insert( CFC_Parachute.MenuToggleButtons, {
        TextOff = "LFS Eject-Launch (Disabled)",
        TextOn = "LFS Eject-Launch (Enabled)",
        ConVar = "cfc_parachute_lfs_eject_launch",
        ConVarServerChoice = "2"
    } )
end


hook.Add( "CFC_Parachute_CheckOptionalDependencies", "CFC_Parachute_SetupLFS", function()
    if not simfphys or not simfphys.LFS then return end

    trySetupLFS()
end )
