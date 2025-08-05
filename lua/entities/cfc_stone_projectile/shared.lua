AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "cfc_cinderblock_projectile"

ENT.PrintName       = "Stone"
ENT.Author          = "StrawWagen"
ENT.Contact         = ""
ENT.Purpose         = "Not very effective."
ENT.Instructions    = "Throw at someone's head!."
ENT.Spawnable       = false

if CLIENT then -- killicon, and language 'translation'
    CFCPvPWeapons.CL_SetupSent( ENT, "cfc_stone_projectile", "materials/vgui/hud/cfc_stone.png" )
end

ENT.Model = Model( "models/props_junk/rock001a.mdl" )
ENT.ModelScale = 0.5

ENT.BaseDamage = 10
ENT.AdditionalDamageStartingVel = 750
ENT.VelocityForOneDamage = 50

ENT.HullSize = 5

-- just a cache
ENT.HullVec = Vector( ENT.HullSize, ENT.HullSize, ENT.HullSize )


function ENT:CinderblockHitEffects( speed )
    local pitch = 180 - ( speed / 25 )

    self:EmitSound( "Rock.ImpactHard", 70, pitch, 1, CHAN_STATIC, bit.bor( SND_CHANGE_PITCH, SND_CHANGE_VOL ) )
end