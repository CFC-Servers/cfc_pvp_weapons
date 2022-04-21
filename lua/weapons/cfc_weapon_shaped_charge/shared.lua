SWEP.Author         = "Redox"
SWEP.Contact        = "CFC Discord"
SWEP.Instructions   = "Right or left click to plant."

SWEP.printName = "Shaped Charge"
SWEP.weapClass = "cfc_weapon_shaped_charge"
SWEP.spawnClass = "cfc_shaped_charge"
SWEP.ammoName = "shapedCharge"
SWEP.plantableOnPlayers = false

game.AddAmmoType( {
    name = SWEP.ammoName,
    dmgtype = DMG_BULLET
} )

SWEP.Spawnable              = false --byebye boring shaped charge

SWEP.ViewModel              = "models/weapons/cstrike/c_c4.mdl"
SWEP.WorldModel             = "models/weapons/w_c4.mdl"
SWEP.HoldType               = "slam"
SWEP.UseHands               = true

SWEP.Primary.ClipSize       = 1
SWEP.Primary.Delay          = 1
SWEP.Primary.DefaultClip    = 1
SWEP.Primary.Automatic      = false
SWEP.Primary.Ammo           = SWEP.ammoName

SWEP.Secondary.ClipSize     = -1
SWEP.Secondary.DefaultClip  = -1
SWEP.Secondary.Automatic    = false
SWEP.Secondary.Ammo         = "none"

CreateConVar( SWEP.spawnClass .. "_chargehealth", 100, { FCVAR_REPLICATED, FCVAR_ARCHIVE }, "Health of sticky placed charges.", 0 )
CreateConVar( SWEP.spawnClass .. "_maxcharges", 1, { FCVAR_REPLICATED, FCVAR_ARCHIVE }, "Maxmium amount of charges active per person at once.", 0 )
CreateConVar( SWEP.spawnClass .. "_timer", 20, { FCVAR_REPLICATED, FCVAR_ARCHIVE }, "The time it takes for a charges to detonate.", 0 )
CreateConVar( SWEP.spawnClass .. "_blastdamage", 0, { FCVAR_REPLICATED, FCVAR_ARCHIVE }, "The damage the explosive does to players when it explodes.", 0 )
CreateConVar( SWEP.spawnClass .. "_blastrange", 0, { FCVAR_REPLICATED, FCVAR_ARCHIVE }, "The damage range the explosion has.", 0 )
CreateConVar( SWEP.spawnClass .. "_tracerange", 42, { FCVAR_REPLICATED, FCVAR_ARCHIVE }, "The range the prop breaking explosion has.", 0 )
CreateConVar( SWEP.spawnClass .. "_defusetime", 1, { FCVAR_REPLICATED, FCVAR_ARCHIVE }, "Time it takes to defuse.", 0 )
CreateConVar( SWEP.spawnClass .. "_planttime", 1, { FCVAR_REPLICATED, FCVAR_ARCHIVE }, "Time it takes to defuse.", 0 )