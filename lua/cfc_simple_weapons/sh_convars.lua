AddCSLuaFile()

module( "cfc_simple_weapons.Convars", package.seeall )

MinDamageMult = CreateConVar( "cfc_simple_weapons_min_damage_mult", 0.2, { FCVAR_ARCHIVE, FCVAR_REPLICATED }, "The minimum percentage of damage a weapon deals regardless of range.", 0, 1 )

if CLIENT then
    SwayScale = CreateClientConVar( "cfc_simple_weapons_swayscale", 1, true, false, "The amount of viewmodel sway to apply to weapons" )
    BobScale = CreateClientConVar( "cfc_simple_weapons_bobscale", 1, true, false, "The amount of viewmodel bob to apply to weapons" )
end
