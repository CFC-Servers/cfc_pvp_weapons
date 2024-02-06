AddCSLuaFile()

module( "cfc_simple_weapons.Convars", package.seeall )

MinDamage = CreateConVar( "cfc_simple_weapons_min_damage", 0.2, { FCVAR_ARCHIVE, FCVAR_REPLICATED }, "The minimum percentage of damage a weapon deals regardless of range.", 0, 1 )

if CLIENT then
    SwayScale = CreateClientConVar( "cfc_simple_weapons_swayscale", 1, true, false, "The amount of viewmodel sway to apply to weapons" )
    BobScale = CreateClientConVar( "cfc_simple_weapons_bobscale", 1, true, false, "The amount of viewmodel bob to apply to weapons" )

    VMOffsetX = CreateClientConVar( "cfc_simple_weapons_vm_offset_x", 0, true, false, "The forward/back offset to use for viewmodels." )
    VMOffsetY = CreateClientConVar( "cfc_simple_weapons_vm_offset_y", 0, true, false, "The left/right offset to use for viewmodels." )
    VMOffsetZ = CreateClientConVar( "cfc_simple_weapons_vm_offset_z", 0, true, false, "The up/down offset to use for viewmodelss." )
end
