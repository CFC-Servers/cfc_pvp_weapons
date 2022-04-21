ENT.Type = "anim"
ENT.Base = "cfc_shaped_charge"

ENT.PrintName       = "Armored Shaped Charge"
ENT.Author          = "Redox"
ENT.Contact         = ""
ENT.Purpose         = "Heavy charge that breaches bases."
ENT.Instructions    = "Use the Armored Shaped Charge SWEP to use this Entity."

ENT.countDownSound = "hl1/fvox/beep.wav"
ENT.countDownPitch = 92
ENT.swepName = "Armored Shaped Charge"
ENT.sparkScale = 10

function ENT:OnTakeDamage( dmg )
    self:EmitSound( "FX_RicochetSound.Ricochet", 100, 100, 1, CHAN_WEAPON )

end

function ENT:PlantEffects()
    self:EmitSound( "physics/metal/metal_canister_impact_soft3.wav", 100, 70, 1, CHAN_STATIC )
    self:EmitSound( "physics/metal/metal_canister_impact_hard3.wav", 100, 120, 1, CHAN_STATIC )
    self:EmitSound( "npc/roller/blade_cut.wav", 100, 90, 1, CHAN_STATIC )

end

function ENT:PreExplodeEffects()
    self:EmitSound( "npc/roller/mine/rmine_blip3.wav", 90, 120, 1, CHAN_STATIC )
    self:EmitSound( "physics/metal/metal_canister_impact_hard2.wav", 100, 130, 1, CHAN_STATIC )
    util.ScreenShake( self:GetPos(), 1, 50, 1, 750 )
end

function ENT:chargeExplodeEffects()
    local effectdata = EffectData()
    effectdata:SetOrigin( self:GetPos() )
    effectdata:SetNormal( -self:GetUp())
    effectdata:SetRadius( 3 )

    util.Effect( "AR2Explosion", effectdata )
    util.Effect( "Explosion", effectdata )

    self:EmitSound( "ambient/explosions/exp3.wav", 110, 80, 1, CHAN_STATIC )
    self:EmitSound( "ambient/levels/labs/electric_explosion3.wav", 100, 80, 1, CHAN_WEAPON )
    self:EmitSound( "weapons/mortar/mortar_explode2.wav", 95, 70, 1, CHAN_WEAPON )

    util.ScreenShake( self:GetPos(), 4, 50, 1, 1000 )

end

function ENT:ChargeAttackPlayer( ply )
    --have to do this hack to make the player crater into the wall when hit
    local info = { 
        Attacker = self.bombOwner or self,
        Damage = 500,
        Force = 5000,
        Distance = 100,
        Dir = -self:GetUp(),
        Src = self:GetPos(),
        IgnoreEntity = self
    } 
	self:FireBullets( info )
    
end