SWEP.Author         = "legokidlogan"
SWEP.Contact        = "CFC Discord"
SWEP.Instructions   = 
    "Left click to open/close chute\n" ..
    "Right click to open customizer\n" ..
    "Hold spacebar to unfurl chute\n" ..
    "Movement keys to glide\n" ..
    "Switching weapons will destabilize the chute"

game.AddAmmoType( {
    name = "parachute",
    dmgtype = DMG_GENERIC
} )

SWEP.Spawnable              = true

SWEP.ViewModel              = "models/weapons/v_c4.mdl"
SWEP.WorldModel             = "models/cfc/parachute/pack.mdl"
SWEP.ViewModelFOV           = -1000

SWEP.Primary.ClipSize       = 1
SWEP.Primary.Delay          = 0.15
SWEP.Primary.DefaultClip    = 1
SWEP.Primary.Automatic      = false
SWEP.Primary.Ammo           = "parachute"

SWEP.Secondary.ClipSize     = -1
SWEP.Secondary.DefaultClip  = -1
SWEP.Secondary.Automatic    = false
SWEP.Secondary.Ammo         = "none"


CreateConVar( "cfc_parachute_drag", 0.007, { FCVAR_REPLICATED, FCVAR_ARCHIVE }, "How slowly you fall while in a furled parachute.", 0, 1 )
CreateConVar( "cfc_parachute_drag_unfurled", 0.028, { FCVAR_REPLICATED, FCVAR_ARCHIVE }, "How slowly you fall while in an unfurled parachute.", 0, 1 )
CreateConVar( "cfc_parachute_speed", 0.007, { FCVAR_REPLICATED, FCVAR_ARCHIVE }, "How quickly you move in a furled parachute, relative to how fast you're falling.", 0, 50000 )
CreateConVar( "cfc_parachute_speed_unfurled", 0.023, { FCVAR_REPLICATED, FCVAR_ARCHIVE }, "How quickly you move in an unfurled parachute, relative to how fast you're falling.", 0, 50000 )
CreateConVar( "cfc_parachute_speed_max", 1400, { FCVAR_REPLICATED, FCVAR_ARCHIVE }, "Max horizontal speed of a parachute", 0, 50000 )

CreateConVar( "cfc_parachute_destabilize_min_gap", 0.1, { FCVAR_REPLICATED, FCVAR_ARCHIVE }, "Minimum time between direction changes while a parachute destabilizes, in seconds.", 0, 50000 )
CreateConVar( "cfc_parachute_destabilize_max_gap", 3, { FCVAR_REPLICATED, FCVAR_ARCHIVE }, "Maximum time between direction changes while a parachute destabilizes, in seconds.", 0, 50000 )
CreateConVar( "cfc_parachute_destabilize_max_direction_change", 40, { FCVAR_REPLICATED, FCVAR_ARCHIVE }, "Maximum angle change in a parachute's direction while it is destabilized.", 0, 180 )
CreateConVar( "cfc_parachute_destabilize_max_lurch", 300, { FCVAR_REPLICATED, FCVAR_ARCHIVE }, "Maximum downwards force a parachute can receive from random lurches while destabilized.", 0, 180 )
CreateConVar( "cfc_parachute_destabilize_lurch_chance", 0.2, { FCVAR_REPLICATED, FCVAR_ARCHIVE }, "The chance for an unstable parachute to lurch downwards when a direction change occurs.", 0, 180 )
CreateConVar( "cfc_parachute_destabilize_shoot_lurch_chance", 0.2, { FCVAR_REPLICATED, FCVAR_ARCHIVE }, "The chance for an unstable parachute to lurch downwards when the player shoots a bullet.", 0, 1 )
CreateConVar( "cfc_parachute_destabilize_shoot_change_chance", 0.15, { FCVAR_REPLICATED, FCVAR_ARCHIVE }, "The chance for an unstable parachute's direction to change when the player shoots a bullet.", 0, 1 )
