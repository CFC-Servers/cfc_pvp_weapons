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


function SWEP:GetViewModelPosition( EyePos, EyeAng )
    canPlace = self:CanPlace()
    local target = 0
    if canPlace then
        target = 2
    else
        target = -1
    end
    self.offset = math.Approach( self.offset or 0, target, 0.08 ) 
    EyePos = EyePos + Vector(0,0,self.offset)
    return EyePos, EyeAng

end