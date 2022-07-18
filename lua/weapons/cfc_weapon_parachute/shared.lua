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


CreateConVar( "cfc_parachute_fall_speed", 450, { FCVAR_REPLICATED, FCVAR_ARCHIVE }, "Target fall speed while in a furled parachute.", 0, 50000 )
CreateConVar( "cfc_parachute_fall_speed_unfurled", 200, { FCVAR_REPLICATED, FCVAR_ARCHIVE }, "Target fall speed while in an unfurled parachute.", 0, 50000 )
CreateConVar( "cfc_parachute_fall_lerp", 0.8, { FCVAR_REPLICATED, FCVAR_ARCHIVE }, "How quickly a parachute will reach its target fall speed.", 0, 10 )
CreateConVar( "cfc_parachute_horizontal_speed", 110, { FCVAR_REPLICATED, FCVAR_ARCHIVE }, "How quickly you move in a furled parachute.", 0, 50000 )
CreateConVar( "cfc_parachute_horizontal_speed_unfurled", 300, { FCVAR_REPLICATED, FCVAR_ARCHIVE }, "How quickly you move in an unfurled parachute.", 0, 50000 )
CreateConVar( "cfc_parachute_horizontal_speed_unstable", 80, { FCVAR_REPLICATED, FCVAR_ARCHIVE }, "How well you can control a parachute while holding another weapon.", 0, 50000 )
CreateConVar( "cfc_parachute_horizontal_speed_limit", 1000, { FCVAR_REPLICATED, FCVAR_ARCHIVE }, "Max horizontal speed of a parachute.", 0, 50000 )
CreateConVar( "cfc_parachute_sprint_boost", 1.5, { FCVAR_REPLICATED, FCVAR_ARCHIVE }, "How much of a horizontal boost you get in a parachute while sprinting.", 1, 10 )
CreateConVar( "cfc_parachute_handling", 2.5, { FCVAR_REPLICATED, FCVAR_ARCHIVE }, "Improves parachute handling by making it easier to brake or chagne directions. 1 gives no handling boost, 0-1 reduces handling.", 0, 10 )

CreateConVar( "cfc_parachute_destabilize_min_gap", 0.1, { FCVAR_REPLICATED, FCVAR_ARCHIVE }, "Minimum time between direction changes while a parachute destabilizes, in seconds.", 0, 50000 )
CreateConVar( "cfc_parachute_destabilize_max_gap", 2.5, { FCVAR_REPLICATED, FCVAR_ARCHIVE }, "Maximum time between direction changes while a parachute destabilizes, in seconds.", 0, 50000 )
CreateConVar( "cfc_parachute_destabilize_max_direction_change", 30, { FCVAR_REPLICATED, FCVAR_ARCHIVE }, "Maximum angle change in a parachute's direction while it is destabilized.", 0, 180 )
CreateConVar( "cfc_parachute_destabilize_max_lurch", 150, { FCVAR_REPLICATED, FCVAR_ARCHIVE }, "Maximum downwards force a parachute can receive from random lurches while destabilized.", 0, 50000 )
CreateConVar( "cfc_parachute_destabilize_max_fall_lurch", 550, { FCVAR_REPLICATED, FCVAR_ARCHIVE }, "Maximum downwards velocity before a parachute stops being affected by lurch. Puts a soft-cap on how fast you plummet from shooting weapons.", 0, 50000 )
CreateConVar( "cfc_parachute_destabilize_lurch_chance", 0.2, { FCVAR_REPLICATED, FCVAR_ARCHIVE }, "The chance for an unstable parachute to lurch downwards when a direction change occurs.", 0, 1 )
CreateConVar( "cfc_parachute_destabilize_shoot_lurch_chance", 0.1, { FCVAR_REPLICATED, FCVAR_ARCHIVE }, "The chance for an unstable parachute to lurch downwards when the player shoots a bullet.", 0, 1 )
CreateConVar( "cfc_parachute_destabilize_shoot_change_chance", 0.25, { FCVAR_REPLICATED, FCVAR_ARCHIVE }, "The chance for an unstable parachute's direction to change when the player shoots a bullet.", 0, 1 )
