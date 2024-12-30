local icol = Color( 255, 255, 255, 255 )
local icolOrange = Color( 255, 80, 0, 255 )

killicon.Add( "cfc_bonk_shotgun", "vgui/hud/cfc_bonk_shotgun", icol )
killicon.Add( "cfc_trash_blaster", "vgui/hud/cfc_trash_blaster", icol ) -- Sadly won't appear since the kills will attribute to generic prop kill instead
killicon.Add( "cfc_ion_cannon", "vgui/hud/cfc_ion_cannon", icol )

killicon.Add( "cfc_graviton_gun", "vgui/hud/cfc_graviton_gun", icolOrange )
killicon.Add( "cfc_simple_ent_cluster_grenade", "vgui/hud/cfc_simple_ent_cluster_grenade", icolOrange )
killicon.Add( "cfc_stinger_launcher", "vgui/hud/cfc_stinger_launcher", icolOrange )
killicon.Add( "cfc_stinger_missile", "vgui/hud/cfc_stinger_launcher", icolOrange ) -- missile/launcher share killicon
