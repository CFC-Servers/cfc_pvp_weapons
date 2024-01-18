AddCSLuaFile( "cfc_pvp_weapons/shared/sh_parachute_convars.lua" )
AddCSLuaFile( "cfc_pvp_weapons/client/cl_parachute.lua" )
AddCSLuaFile( "cfc_pvp_weapons/client/cl_parachute_lfs.lua" )

include( "cfc_pvp_weapons/shared/sh_parachute_convars.lua" )

if SERVER then
    include( "cfc_pvp_weapons/server/sv_parachute_convars.lua" )
    include( "cfc_pvp_weapons/server/sv_parachute.lua" )
    include( "cfc_pvp_weapons/server/sv_parachute_lfs.lua" )

    resource.AddFile( "materials/models/cfc/cfc_logo.vmt" )
    resource.AddFile( "materials/models/cfc/cfc_logo_transparent.vmt" )
else
    include( "cfc_pvp_weapons/client/cl_parachute.lua" )
    include( "cfc_pvp_weapons/client/cl_parachute_lfs.lua" )
end
