if SERVER then
    AddCSLuaFile( "shared.lua" )

end

SWEP.Base = "cfc_slappers"
SWEP.Spawnable = true
SWEP.AdminOnly = true
SWEP.PrintName = "Super Slappers"
SWEP.Purpose = "Super Slap"
SWEP.Category = "CFC"
SWEP.Slot = 1
SWEP.SlotPos = 0

SWEP.Primary = {
    ClipSize = -1,
    Delay = 1.2,
    DefaultClip = -1,
    Automatic = false,
    Ammo = "none"
}

SWEP.Secondary = SWEP.Primary

SWEP.SuperSlapSounds = {
    -- all the really strong slap sounds
    Slap = {
        Sound( "elevator/effects/slap_hit06.wav" ),
        Sound( "elevator/effects/slap_hit07.wav" ),
        Sound( "elevator/effects/slap_hit09.wav" )
    }
}

function SWEP:ForceMul()
    return 10
end

function SWEP:WeaponKnockWeight()
    return 8
end

function SWEP:Pitch( pitch )
    return pitch + -55
end

function SWEP:Level( level )
    return level + 30
end

function SWEP:SlapEffects( slappedPos )
    util.ScreenShake( slappedPos, 30, 20, 0.4, 1000 ) -- strong for nearby
    util.ScreenShake( slappedPos, 1, 20, 2, 4000 ) -- weak for far away

end

function SWEP:MissEffect()
    util.ScreenShake( self:GetOwner():GetPos(), 10, 1, 0.4, 500 ) -- strong for nearby
    util.ScreenShake( self:GetOwner():GetPos(), 0.5, 1, 2, 4000 ) -- weak for far away

end

function SWEP:SlapSound()
    for _ = 1, 4 do
        self:playRandomSound( self:GetOwner(), self.SuperSlapSounds.Slap, self:Level( 80 ), self:Pitch( math.random( 92, 108 ) ) )

    end
end

function SWEP:ViewPunchSlapper( ent, punchAng )
    ent:ViewPunch( punchAng * 8 )

end
