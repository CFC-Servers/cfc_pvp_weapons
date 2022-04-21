ENT.Type = "anim"
ENT.Base = "base_gmodentity"

ENT.PrintName       = "Shaped Charge"
ENT.Author          = "Redox"
ENT.Contact         = ""
ENT.Purpose         = "Breaches bases."
ENT.Instructions    = "Use the Shaped Charge SWEP to use this Entity."

ENT.swepModel = "models/weapons/w_c4_planted.mdl"
ENT.modelScale = 1
ENT.countDownSound = "weapons/c4/c4_beep1.wav"
ENT.countDownPitch = 100
ENT.sparkScale = 8

ENT.swepName = "Shaped Charge"

function ENT:chargeExplodeEffects()
    local effectdata = EffectData()
    effectdata:SetOrigin( self:GetPos() )
    effectdata:SetNormal( -self:GetUp())
    effectdata:SetRadius( 3 )

    util.Effect( "AR2Explosion", effectdata )
    util.Effect( "Explosion", effectdata )

    self:EmitSound( "npc/strider/strider_step4.wav", 100, 100, 1, CHAN_STATIC )
    self:EmitSound( "weapons/mortar/mortar_explode2.wav", 110, 100, 1, CHAN_WEAPON )
end