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


SWEP.CFC_FirstTimeHints = {
    {
        Message = "Place a Shaped Charge on your enemy's base, then protect it until it detonates.",
        Sound = "ambient/water/drip1.wav",
        Duration = 10,
        DelayNext = 7,
    },
    {
        Message = "Shaped Charges delete everything in a short line behind them, no matter how durable.",
        Sound = "ambient/water/drip2.wav",
        Duration = 8,
        DelayNext = 0,
    },
}
