SWEP.Author         = "Redox"
SWEP.Contact        = "CFC Discord"
SWEP.Instructions   = "Right or left click to plant."
SWEP.Base = "cfc_weapon_shaped_charge"

SWEP.printName = "Sticky Shaped Charge"
SWEP.weapClass = "cfc_weapon_shaped_charge_sticky"
SWEP.spawnClass = "cfc_shaped_charge_sticky"
SWEP.ammoName = "stickyShapedCharge"
SWEP.plantableOnPlayers = true

game.AddAmmoType( {
    name = SWEP.ammoName,
    dmgtype = DMG_BULLET
} )

SWEP.Spawnable              = true

SWEP.Primary.Ammo           = SWEP.ammoName

CreateConVar( SWEP.spawnClass .. "_chargehealth", 20, { FCVAR_REPLICATED, FCVAR_ARCHIVE }, "Health of sticky placed charges.", 0 )
CreateConVar( SWEP.spawnClass .. "_maxcharges", 1, { FCVAR_REPLICATED, FCVAR_ARCHIVE }, "Maxmium amount of charges active per person at once.", 0 )
CreateConVar( SWEP.spawnClass .. "_timer", 20, { FCVAR_REPLICATED, FCVAR_ARCHIVE }, "The time it takes for a charges to detonate.", 0 )
CreateConVar( SWEP.spawnClass .. "_blastdamage", 30, { FCVAR_REPLICATED, FCVAR_ARCHIVE }, "The damage the explosive does to players when it explodes.", 0 )
CreateConVar( SWEP.spawnClass .. "_blastrange", 150, { FCVAR_REPLICATED, FCVAR_ARCHIVE }, "The damage range the explosion has.", 0 )
CreateConVar( SWEP.spawnClass .. "_tracerange", 5, { FCVAR_REPLICATED, FCVAR_ARCHIVE }, "The range the prop breaking explosion has.", 0 )
CreateConVar( SWEP.spawnClass .. "_defusetime", 0, { FCVAR_REPLICATED, FCVAR_ARCHIVE }, "Time it takes to defuse.", 0 )
CreateConVar( SWEP.spawnClass .. "_planttime", 0, { FCVAR_REPLICATED, FCVAR_ARCHIVE }, "Time it takes to defuse.", 0 )