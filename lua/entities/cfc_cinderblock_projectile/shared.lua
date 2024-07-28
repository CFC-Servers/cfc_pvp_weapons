AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "cfc_rotten_tomato_projectile"

ENT.PrintName       = "Cinder Block"
ENT.Author          = "StrawWagen"
ENT.Contact         = ""
ENT.Purpose         = "Look out below!."
ENT.Instructions    = "Drop off of buildings."
ENT.Spawnable       = false

ENT.Model = Model( "models/props_debris/concrete_cynderblock001.mdl" )
ENT.ModelScale = 1

ENT.BaseDamage = 25
ENT.AdditionalDamageStartingVel = 500
ENT.VelocityForOneDamage = 8

ENT.HullSize = 10

-- just a cache
ENT.HullVec = Vector( ENT.HullSize, ENT.HullSize, ENT.HullSize )

function ENT:HitEffects( _, _, speed )
    local pitch = 180 - ( speed / 25 )

    self:EmitSound( "Concrete_Block.ImpactHard", 70, pitch, 1, CHAN_STATIC, bit.bor( SND_CHANGE_PITCH, SND_CHANGE_VOL ) )
    self:EmitSound( "physics/concrete/concrete_block_impact_hard2.wav", 70, 80, 1, CHAN_STATIC )
end

local vec_up = Vector( 0, 0, 1 )

function ENT:PostHitEnt( hitEnt, damageDealt )
    local critical = damageDealt >= 100

    util.ScreenShake( self:WorldSpaceCenter(), 5 + ( damageDealt * 0.5 ), 20, 0.5, 500 + damageDealt * 2 )
    util.ScreenShake( self:WorldSpaceCenter(), 5, 20, 0.1, 1500 + damageDealt )

    local gib = ents.Create( "prop_physics" )

    if IsValid( gib ) then
        gib:SetCollisionGroup( COLLISION_GROUP_WEAPON )
        gib:SetPos( self:GetPos() -self:GetVelocity():GetNormalized() * 10 )
        gib:SetAngles( self:GetAngles() )
        gib:SetModel( self.Model )
        gib:SetMaterial( self:GetMaterial() )
        gib:Spawn()

        local gibsObj = gib:GetPhysicsObject()

        if critical then
            gibsObj:SetVelocity( vec_up * damageDealt * 2 )
            gibsObj:ApplyTorqueCenter( vec_up * damageDealt * 2 )
        else
            gibsObj:SetVelocity( self:GetVelocity() / 2 )
        end

        SafeRemoveEntityDelayed( gib, 5 )
    end
    if not ( hitEnt:IsPlayer() or hitEnt:IsNPC() ) then return end
    if critical then
        self:EmitSound( "physics/concrete/concrete_block_impact_hard" .. math.random( 1, 3 ) .. ".wav", 90, math.random( 40, 50 ), 1, CHAN_STATIC )
        self:EmitSound( "Flesh.ImpactHard", 90, 70, 1, CHAN_STATIC )
        self:EmitSound( "Breakable.MatFlesh", 90, 70, 1, CHAN_STATIC )
    end
end