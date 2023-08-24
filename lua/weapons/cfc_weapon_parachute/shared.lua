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
