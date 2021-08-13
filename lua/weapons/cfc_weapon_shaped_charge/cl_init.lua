include( "shared.lua" )

language.Add( "shapedCharge_ammo", "Shaped Charge" )

SWEP.PrintName      = "Shaped Charge"
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
