include( "shared.lua" )

language.Add( "parachute_ammo", "Parachute" )

SWEP.PrintName      = "Parachute"
SWEP.Category       = "CFC"

SWEP.Slot           = 4
SWEP.SlotPos        = 2

SWEP.DrawCrosshair  = true
SWEP.DrawAmmo       = false

CFC_Parachute = CFC_Parachute or {}

function SWEP:PrimaryAttack()
    return
end

function SWEP:SecondaryAttack()
    CFC_Parachute.OpenDesignMenu()

    return
end
