AddCSLuaFile()

DEFINE_BASECLASS( "cfc_simple_ent_grenade_base" )

ENT.Base = "cfc_simple_ent_grenade_base"

ENT.Model = Model( "models/weapons/w_eq_fraggrenade.mdl" )

ENT.Damage = 100 -- Doesn't actually deal damage, just used to compare against damage falloff for scaling the knockback.
ENT.Radius = 300
ENT.Knockback = 1000 * 40
ENT.PlayerKnockback = 600
ENT.PlayerSelfKnockback = 400
ENT.PlayerKnockbackVelAdd = Vector( 0, 0, 200 )


function ENT:SetTimer( delay )
    BaseClass.SetTimer( self, delay )

    self.Beep = CurTime()
end

function ENT:Initialize()
    BaseClass.Initialize( self )
end

function ENT:Explode()
    local pos = self:WorldSpaceCenter()
    local attacker = self:GetOwner()

    local dmgInfoInit = DamageInfo()
    dmgInfoInit:SetAttacker( attacker )
    dmgInfoInit:SetInflictor( self )
    dmgInfoInit:SetDamage( self.Damage )
    dmgInfoInit:SetDamageType( DMG_SONIC ) -- Don't use DMG_BLAST, otherwise rocket jump addons will also try to apply knockback (or even scale the damage)

    local knockback = self.Knockback
    local playerKnockback = self.PlayerKnockback
    local playerSelfKnockback = self.PlayerSelfKnockback
    local playerKnockbackVelAdd = self.PlayerKnockbackVelAdd

    CFCPvPWeapons.BlastDamageInfo( dmgInfoInit, pos, self.Radius, function( victim, dmgInfo )
        if victim == self then return true end
        if not IsValid( victim ) then return end

        local forceDir = dmgInfo:GetDamageForce()
        local forceLength = forceDir:Length()
        if forceLength == 0 then return true end

        forceDir = forceDir / forceLength

        local force = forceDir * dmgInfo:GetDamage() / self.Damage

        if victim:IsPlayer() then
            force = force * ( victim == attacker and playerSelfKnockback or playerKnockback )
            victim:SetVelocity( force + playerKnockbackVelAdd )
        else
            local physObj = victim:GetPhysicsObject()
            if not IsValid( physObj ) then return true end

            force = force * knockback
            physObj:ApplyForceCenter( force )
        end

        return true
    end )

    local effect = EffectData()
    effect:SetStart( pos )
    effect:SetOrigin( pos )

    util.Effect( "Explosion", effect, true, true )
    util.Effect( "cball_explode", effect, true, true )

    sound.Play( "npc/assassin/ball_zap1.wav", pos, 90, 100 )

    self:Remove()
end

function ENT:Think()
    if SERVER and self.Beep and self.Beep <= CurTime() then
        self:EmitSound( "npc/roller/mine/combine_mine_deploy1.wav", 75, 120 )

        local time = 1

        if self.Detonate and self.Detonate - CurTime() <= 1.5 then
            time = 0.3
        end

        self.Beep = CurTime() + time
    end

    BaseClass.Think( self )

    return true
end
