AddCSLuaFile()

DEFINE_BASECLASS( "cfc_simple_ent_grenade_base" )

ENT.Base = "cfc_simple_ent_grenade_base"

ENT.Model = Model( "models/weapons/w_eq_fraggrenade.mdl" )

ENT.BeepEnabled = true
ENT.BeepDelay = 1
ENT.BeepDelayFast = 0.3
ENT.BeepFastThreshold = 1.5

ENT.Damage = 100 -- Doesn't actually deal damage, just used to compare against damage falloff for scaling the knockback.
ENT.ParachuteDamageScale = 0.75 -- For every fake "Damage" dealt, deal this much damage to target's parachute ( if it's deployed )
ENT.Radius = 300
ENT.Knockback = 1000 * 40
ENT.PlayerKnockback = 600
ENT.PlayerSelfKnockback = 450
ENT.PlayerKnockbackVertConstant = 200 -- Vertical force added to players which goes up/down depending on the initial force. Does NOT scale with explosion falloff.
ENT.PlayerKnockbackVertScaled = 300 -- Vertical force added to players which goes up/down depending on the initial force. Scales with explosion falloff.


function ENT:Initialize()
    BaseClass.Initialize( self )

    self:SetMaterial( "models/weapons/w_models/cfc_frag_grenade/frag_grenade_bonk" )
end

function ENT:Explode()
    local pos = self:WorldSpaceCenter()
    local attacker = self:GetOwner()

    local baseDamage = self.Damage
    local dmgInfoInit = DamageInfo()
    dmgInfoInit:SetAttacker( attacker )
    dmgInfoInit:SetInflictor( self )
    dmgInfoInit:SetDamage( baseDamage )
    dmgInfoInit:SetDamageType( DMG_SONIC ) -- Don't use DMG_BLAST, otherwise rocket jump addons will also try to apply knockback (or even scale the damage)

    local knockback = self.Knockback
    local playerKnockback = self.PlayerKnockback
    local playerSelfKnockback = self.PlayerSelfKnockback
    local playerKnockbackVertConstant = self.PlayerKnockbackVertConstant
    local playerKnockbackVertScaled = self.PlayerKnockbackVertScaled
    local wep = self._discombobWep

    CFCPvPWeapons.BlastDamageInfo( dmgInfoInit, pos, self.Radius, function( victim, dmgInfo )
        if victim == self then return true end
        if not IsValid( victim ) then return end

        local forceDir = dmgInfo:GetDamageForce()
        local forceLength = forceDir:Length()
        if forceLength == 0 then return true end

        forceDir = forceDir / forceLength

        local damageDealt = dmgInfo:GetDamage()
        local damageFrac = damageDealt / baseDamage
        local force = forceDir * damageFrac

        if victim:IsPlayer() then
            if not victim:Alive() then return true end

            force = force * ( victim == attacker and playerSelfKnockback or playerKnockback )

            -- If the explosion was caused by an impact with the player, the movement caused by the collison overrides our :SetVelocity() call.
            -- It ignores it even with a delay of 0 (i.e. the next tick), but delaying by 1 tick interval (i.e. the next next tick) works.
            timer.Simple( engine.TickInterval(), function()
                if not IsValid( victim ) then return end

                local z = force[3]

                if z >= 0 then
                    force[3] = z + playerKnockbackVertConstant + playerKnockbackVertScaled * damageFrac
                else
                    force[3] = z - playerKnockbackVertConstant - playerKnockbackVertScaled * damageFrac
                end

                victim:SetVelocity( force )
            end )
        else
            local physObj = victim:GetPhysicsObject()
            if not IsValid( physObj ) then return true end

            force = force * knockback
            physObj:ApplyForceCenter( force )
        end

        if wep and wep.Bonk and victim ~= attacker and victim.Alive and victim:Alive() then
            CFCPvPWeapons.ArbitraryBonk( victim, attacker, wep )
        end

        if victim.cfcParachuteChute and victim.cfcParachuteChute:GetIsOpen() then
            local chuteDmg = damageDealt * self.ParachuteDamageScale
            victim.cfcParachuteChute:ChuteTakeDamage( chuteDmg )
        end

        return true
    end )

    local effect = EffectData()
    effect:SetStart( pos )
    effect:SetOrigin( pos )
    effect:SetFlags( 0x4 )

    util.Effect( "Explosion", effect, true, true )
    util.Effect( "cball_explode", effect, true, true )

    sound.Play( "hl1/ambience/steamburst1.wav", pos, 90, math.random( 150, 160 ) )
    sound.Play( "weapons/physcannon/superphys_launch3.wav", pos, 83, math.random( 180, 200 ) )
    sound.Play( "garrysmod/balloon_pop_cute.wav", pos, 90, math.random( 40, 50 ), 0.4 )

    self:Remove()
end

function ENT:PlayBeep()
    self:EmitSound( "npc/roller/mine/rmine_taunt1.wav", 75, 120 )
    self:EmitSound( "npc/roller/mine/rmine_taunt1.wav", 75, 123 )
end
