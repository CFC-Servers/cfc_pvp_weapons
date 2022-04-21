SWEP.Author         = "Redox"
SWEP.Contact        = "CFC Discord"
SWEP.Instructions   = "Right or left click to plant."
SWEP.Base = "cfc_weapon_shaped_charge"

SWEP.printName = "Armored Shaped Charge"
SWEP.weapClass = "cfc_weapon_shaped_charge_armored"
SWEP.spawnClass = "cfc_shaped_charge_armored"
SWEP.ammoName = "armoredShapedCharge"

game.AddAmmoType( {
    name = SWEP.ammoName,
    dmgtype = DMG_BULLET
} )

SWEP.Spawnable              = true

SWEP.Primary.Ammo           = SWEP.ammoName

CreateConVar( SWEP.spawnClass .. "_chargehealth", 200, { FCVAR_REPLICATED, FCVAR_ARCHIVE }, "Health of armored placed charges.", 0 )
CreateConVar( SWEP.spawnClass .. "_maxcharges", 1, { FCVAR_REPLICATED, FCVAR_ARCHIVE }, "Maxmium amount of charges active per person at once.", 0 )
CreateConVar( SWEP.spawnClass .. "_timer", 30, { FCVAR_REPLICATED, FCVAR_ARCHIVE }, "The time it takes for a charges to detonate.", 0 )
CreateConVar( SWEP.spawnClass .. "_blastdamage", 180, { FCVAR_REPLICATED, FCVAR_ARCHIVE }, "The damage the explosive does to players when it explodes.", 0 )
CreateConVar( SWEP.spawnClass .. "_blastrange", 300, { FCVAR_REPLICATED, FCVAR_ARCHIVE }, "The damage range the explosion has.", 0 )
CreateConVar( SWEP.spawnClass .. "_tracerange", 62, { FCVAR_REPLICATED, FCVAR_ARCHIVE }, "The range the prop breaking explosion has.", 0 )
CreateConVar( SWEP.spawnClass .. "_defusetime", 5, { FCVAR_REPLICATED, FCVAR_ARCHIVE }, "Time it takes to defuse.", 0 )
CreateConVar( SWEP.spawnClass .. "_planttime", 4, { FCVAR_REPLICATED, FCVAR_ARCHIVE }, "Time it takes to defuse.", 0 )