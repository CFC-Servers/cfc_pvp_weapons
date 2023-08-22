AddCSLuaFile( "cfc_pvp_weapons/client/cl_parachute.lua" )

if SERVER then
    include( "cfc_pvp_weapons/server/sv_parachute.lua" )
else
    include( "cfc_pvp_weapons/client/cl_parachute.lua" )
end
