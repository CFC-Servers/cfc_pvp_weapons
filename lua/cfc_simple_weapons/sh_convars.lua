AddCSLuaFile()

module( "cfc_simple_weapons.Convars", package.seeall )

MinDamage = CreateConVar( "cfc_simple_weapons_min_damage", 0.2, { FCVAR_ARCHIVE, FCVAR_REPLICATED }, "The minimum percentage of damage a weapon deals regardless of range.", 0, 1 )
Falloff = CreateConVar( "cfc_simple_weapons_falloff_mult", 1, { FCVAR_ARCHIVE, FCVAR_REPLICATED }, "How aggressively damage falloff applies.", 0 )

DamageMult = CreateConVar( "cfc_simple_weapons_damage_mult", 1, { FCVAR_ARCHIVE, FCVAR_REPLICATED }, "The damage modifier to use for weapons.", 0 )
NPCDamageMult = CreateConVar( "cfc_simple_weapons_npc_damage_mult", 0.5, { FCVAR_ARCHIVE, FCVAR_REPLICATED }, "The damage modifier to use for weapons when held by NPC's.", 0 )
RangeMult = CreateConVar( "cfc_simple_weapons_range_mult", 1, { FCVAR_ARCHIVE, FCVAR_REPLICATED }, "The range modifier to use for weapons.", 0 )
RecoilMult = CreateConVar( "cfc_simple_weapons_recoil_mult", 1, { FCVAR_ARCHIVE, FCVAR_REPLICATED }, "The recoil modifier to use for weapons.", 0 )

if CLIENT then
    AutoReload = CreateClientConVar( "cfc_simple_weapons_auto_reload", 1, true, true, "Whether weapons should automatically reload when you fire them." )

    UseScopes = CreateClientConVar( "cfc_simple_weapons_scopes", 1, true, false, "Whether to use scopes when zooming." )

    SwayScale = CreateClientConVar( "cfc_simple_weapons_swayscale", 1, true, false, "The amount of viewmodel sway to apply to weapons" )
    BobScale = CreateClientConVar( "cfc_simple_weapons_bobscale", 1, true, false, "The amount of viewmodel bob to apply to weapons" )

    VMOffsetX = CreateClientConVar( "cfc_simple_weapons_vm_offset_x", 0, true, false, "The forward/back offset to use for viewmodels." )
    VMOffsetY = CreateClientConVar( "cfc_simple_weapons_vm_offset_y", 0, true, false, "The left/right offset to use for viewmodels." )
    VMOffsetZ = CreateClientConVar( "cfc_simple_weapons_vm_offset_z", 0, true, false, "The up/down offset to use for viewmodelss." )
end
