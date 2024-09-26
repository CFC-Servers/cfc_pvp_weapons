AddCSLuaFile()

DEFINE_BASECLASS( "cfc_simple_ent_grenade_base" )

ENT.Base = "cfc_simple_ent_grenade_base"

ENT.Model = Model( "models/weapons/w_eq_fraggrenade.mdl" )

ENT.Damage = 100 -- Doesn't actually deal damage, just used to compare against damage falloff for scaling the duration.
ENT.Radius = 400
ENT.Duration = 3
ENT.GravityMult = -0.15
ENT.PushStrength = 260 -- Pushes the player up to get them off the ground.


function ENT:SetTimer( delay )
    BaseClass.SetTimer( self, delay )

    self.Beep = CurTime()
end

function ENT:Initialize()
    BaseClass.Initialize( self )

    self:SetMaterial( "models/weapons/w_models/cfc_frag_grenade/frag_grenade_antigrav" )
end

function ENT:Explode()
    local pos = self:WorldSpaceCenter()
    local attacker = self:GetOwner()

    local dmgInfoInit = DamageInfo()
    dmgInfoInit:SetAttacker( attacker )
    dmgInfoInit:SetInflictor( self )
    dmgInfoInit:SetDamage( self.Damage )
    dmgInfoInit:SetDamageType( DMG_SONIC ) -- Don't use DMG_BLAST, otherwise rocket jump addons will also try to apply knockback (or even scale the damage)

    local damage = self.Damage
    local duration = self.Duration
    local gravityMult = self.GravityMult
    local pushVel = Vector( 0, 0, self.PushStrength )

    local effect = EffectData()
    effect:SetOrigin( pos )
    effect:SetRadius( 80 )
    effect:SetNormal( Vector( 0, 0, 1 ) )

    util.Effect( "VortDispel", effect, true, true )
    util.Effect( "AR2Explosion", effect, true, true )
    util.Effect( "cball_explode", effect, true, true )

    CFCPvPWeapons.BlastDamageInfo( dmgInfoInit, pos, self.Radius, function( victim, dmgInfo )
        if victim == self then return true end
        if not IsValid( victim ) then return end
        if not victim:IsPlayer() then return true end

        victim:SetGravity( gravityMult )

        if victim:IsOnGround() then
            victim:SetVelocity( pushVel )
        end

        timer.Create( "CFC_PvPWeapons_AntiGravityGrenade_Restore_" .. victim:SteamID(), duration * dmgInfo:GetDamage() / damage, 1, function()
            if not IsValid( victim ) then return end

            victim:SetGravity( 1 )
        end )

        return true
    end )

    sound.Play( "ambient/levels/labs/electric_explosion1.wav", pos, 90, 110 )
    sound.Play( "ambient/fire/ignite.wav", pos, 90, 75, 0.5 )
    sound.Play( "ambient/machines/machine1_hit2.wav", pos, 90, 100 )

    self:Remove()
end

function ENT:Think()
    if SERVER and self.Beep and self.Beep <= CurTime() then
        self:EmitSound( "npc/scanner/combat_scan4.wav", 75, 120 )

        local time = 1

        if self._explodeTime and self._explodeTime - CurTime() <= 1.5 then
            time = 0.3
        end

        self.Beep = CurTime() + time
    end

    BaseClass.Think( self )

    return true
end
