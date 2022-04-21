include( "shared.lua" )

language.Add( SWEP.Primary.Ammo .. "_ammo", SWEP.printName )

SWEP.PrintName      = SWEP.printName
SWEP.Category       = "CFC"

SWEP.Slot           = 4
SWEP.SlotPos        = 1

SWEP.DrawCrosshair  = true
SWEP.DrawAmmo       = true

function SWEP:PrimaryAttack()
    return
end

function SWEP:SecondaryAttack()
    return
end
