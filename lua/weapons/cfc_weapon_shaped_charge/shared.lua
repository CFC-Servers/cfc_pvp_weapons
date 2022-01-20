SWEP.Author         = "Redox"
SWEP.Contact        = "CFC Discord"
SWEP.Instructions   = "Right or left click to plant."

game.AddAmmoType( {
    name = "shapedCharge",
    dmgtype = DMG_BULLET
} )

SWEP.Spawnable              = true

SWEP.ViewModel              = "models/weapons/cstrike/c_c4.mdl"
SWEP.WorldModel             = "models/weapons/w_c4.mdl"
SWEP.HoldType               = "slam"
SWEP.UseHands               = true

SWEP.Primary.ClipSize       = 1
SWEP.Primary.Delay          = 3
SWEP.Primary.DefaultClip    = 1
SWEP.Primary.Automatic      = false
SWEP.Primary.Ammo           = "shapedCharge"

SWEP.Secondary.ClipSize     = -1
SWEP.Secondary.DefaultClip  = -1
SWEP.Secondary.Automatic    = false
SWEP.Secondary.Ammo         = "none"

CreateConVar( "cfc_shaped_charge_chargehealth", 100, { FCVAR_REPLICATED, FCVAR_ARCHIVE }, "Health of placed charges.", 0 )
CreateConVar( "cfc_shaped_charge_maxcharges", 1, { FCVAR_REPLICATED, FCVAR_ARCHIVE }, "Maxmium amount of charges active per person at once.", 0 )
CreateConVar( "cfc_shaped_charge_timer", 10, { FCVAR_REPLICATED, FCVAR_ARCHIVE }, "The time it takes for a charges to detonate.", 0 )
CreateConVar( "cfc_shaped_charge_blastdamage", 0, { FCVAR_REPLICATED, FCVAR_ARCHIVE }, "The damage the explosive does to players when it explodes.", 0 )
CreateConVar( "cfc_shaped_charge_blastrange", 100, { FCVAR_REPLICATED, FCVAR_ARCHIVE }, "The damage range the explosion has.", 0 )
CreateConVar( "cfc_shaped_charge_tracerange", 100, { FCVAR_REPLICATED, FCVAR_ARCHIVE }, "The range the prop breaking explosion has.", 0 )
