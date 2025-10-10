CFCPvPWeapons = CFCPvPWeapons or {}
CFCPvPWeapons.CustomKillIconClasses = CFCPvPWeapons.CustomKillIconClasses or {}

local icol = Color( 255, 255, 255, 255 )
local icolOrange = Color( 255, 80, 0, 255 )

-- These use dynamic killicons and need their regular killicons to be blocked.
-- On the server, define SWEP:CFCPvPWeapons_GetKillIcon( victim, attacker ) to return the custom killicon name.
table.Merge( CFCPvPWeapons.CustomKillIconClasses, {
    ["cfc_gamblers_revolver"] = true,
    ["cfc_gamblers_revolver_golden"] = true,
} )


killicon.Add( "cfc_bonk_shotgun", "vgui/hud/cfc_bonk_shotgun", icol )
killicon.Add( "cfc_trash_blaster", "vgui/hud/cfc_trash_blaster", icol ) -- Sadly won't appear since the kills will attribute to generic prop kill instead
killicon.Add( "cfc_ion_cannon", "vgui/hud/cfc_ion_cannon", icol )
killicon.Add( "cfc_graviton_gun", "vgui/hud/cfc_graviton_gun", icolOrange )
killicon.Add( "cfc_simple_ent_cluster_grenade", "vgui/hud/cfc_simple_ent_cluster_grenade", icolOrange )

killicon.Add( "cfc_stinger_launcher", "vgui/hud/cfc_stinger_launcher", icolOrange )
killicon.Add( "cfc_stinger_missile", "vgui/hud/cfc_stinger_launcher", icolOrange ) -- missile/launcher share killicon
killicon.Add( "cfc_gamblers_revolver_rusty_unlucky", "vgui/hud/cfc_gamblers_revolver/rusty_unlucky", icolOrange )
killicon.Add( "cfc_gamblers_revolver_rusty_regular", "vgui/hud/cfc_gamblers_revolver/rusty_regular", icolOrange )
killicon.Add( "cfc_gamblers_revolver_rusty_lucky", "vgui/hud/cfc_gamblers_revolver/rusty_lucky", icolOrange )
killicon.Add( "cfc_gamblers_revolver_rusty_superlucky", "vgui/hud/cfc_gamblers_revolver/rusty_superlucky", icolOrange )
killicon.Add( "cfc_gamblers_revolver_golden_unlucky", "vgui/hud/cfc_gamblers_revolver/golden_unlucky", icolOrange )
killicon.Add( "cfc_gamblers_revolver_golden_regular", "vgui/hud/cfc_gamblers_revolver/golden_regular", icolOrange )
killicon.Add( "cfc_gamblers_revolver_golden_lucky", "vgui/hud/cfc_gamblers_revolver/golden_lucky", icolOrange )
killicon.Add( "cfc_gamblers_revolver_golden_superlucky", "vgui/hud/cfc_gamblers_revolver/golden_superlucky", icolOrange )


hook.Add( "AddDeathNotice", "CFC_PvPWeapons_CustomKillIcons", function( _, _, inflictorClass )
    if CFCPvPWeapons.CustomKillIconClasses[inflictorClass] then return false end
end )
