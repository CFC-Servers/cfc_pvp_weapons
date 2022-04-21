ENT.Type = "anim"
ENT.Base = "cfc_shaped_charge"

ENT.PrintName       = "Sticky Shaped Charge"
ENT.Author          = "Redox"
ENT.Contact         = ""
ENT.Purpose         = "Light charge that breaches contraptions."
ENT.Instructions    = "Use the Sticky Shaped Charge SWEP to use this Entity."

ENT.countDownSound = "weapons/c4/c4_beep1.wav"
ENT.countDownPitch = 105
ENT.swepName = "Sticky Shaped Charge"
ENT.modelScale = 0.75
ENT.sparkScale = 3
ENT.ColorIdentity = Color( 0, 255, 0 )

function ENT:PlantEffects()
    self:EmitSound( "physics/body/body_medium_impact_hard6.wav", 95, 80, 1, CHAN_STATIC )
    self:EmitSound( "physics/flesh/flesh_squishy_impact_hard3.wav", 95, 120, 1, CHAN_STATIC )

end

function ENT:OnTakeDamage( dmg )
    if dmg:GetInflictor() == self then return end
    self.bombHealth = self.bombHealth - dmg:GetDamage()
    if self.bombHealth <= 0 then
        self:PropBreak( dmg:GetAttacker() )
    end
    local effectdata = EffectData()
    effectdata:SetOrigin( self:GetPos() )
    effectdata:SetScale( 0.5 )
    effectdata:SetMagnitude( 1 )

    util.Effect( "Sparks", effectdata )

    self:EmitSound( "Plastic_Box.Break", 100, 100, 1, CHAN_WEAPON )
    self:EmitSound( "weapons/bugbait/bugbait_squeeze1.wav", 100, 160, 1, CHAN_WEAPON )
    self:EmitSound( "Flesh_Bloody.ImpactHard", 100, 100, 1, CHAN_WEAPON )
end

function ENT:chargeExplodeEffects()
    local effectdata = EffectData()
    effectdata:SetOrigin( self:GetPos() )
    effectdata:SetNormal( -self:GetUp())
    effectdata:SetRadius( 3 )

    util.Effect( "AR2Explosion", effectdata )
    util.Effect( "Explosion", effectdata )

    self:EmitSound( "ambient/levels/labs/electric_explosion5.wav", 95, 100, 1, CHAN_STATIC )
    self:EmitSound( "garrysmod/balloon_pop_cute.wav", 95, 40, 1, CHAN_WEAPON )

end

function ENT:ChargeAttackPlayer( ply )
    for _ = 1, 2 do
        util.Decal( "PaintSplatGreen", self:GetPos() + ( self:GetUp() * 10 ), self:GetPos() + ( -self:GetUp() * 50 ), self )
    end 
end

function ENT:PreExplodeEffects()
    self:EmitSound( "physics/flesh/flesh_squishy_impact_hard3.wav", 90, 120, 1, CHAN_STATIC )
    self:EmitSound( "weapons/bugbait/bugbait_squeeze3.wav", 90, 130, 1, CHAN_STATIC )
    util.ScreenShake( self:GetPos(), 0.5, 50, 0.5, 500 )
end