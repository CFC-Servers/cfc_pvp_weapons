resource.AddWorkshop( "3097864891" )

AddCSLuaFile( "cfc_pvp_weapons/utils.lua" )
include( "cfc_pvp_weapons/utils.lua" )

if SERVER then
    include( "cfc_pvp_weapons/server/utils.lua" )
    include( "cfc_pvp_weapons/server/hitgroup_normalization.lua" )
end
