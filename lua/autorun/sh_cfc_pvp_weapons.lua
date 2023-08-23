AddCSLuaFile( "cfc_pvp_weapons/client/cl_parachute.lua" )
AddCSLuaFile( "cfc_pvp_weapons/client/cl_parachute_lfs.lua" )

if SERVER then
    include( "cfc_pvp_weapons/server/sv_parachute.lua" )
    include( "cfc_pvp_weapons/server/sv_parachute_lfs.lua" )
else
    include( "cfc_pvp_weapons/client/cl_parachute.lua" )
    include( "cfc_pvp_weapons/client/cl_parachute_lfs.lua" )
end
