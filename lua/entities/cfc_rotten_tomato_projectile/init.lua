AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
include( "shared.lua" )

util.AddNetworkString( "cfc_weapons_tomato_screentomato" )

function ENT:Initialize()
    self:SetModel( self.Model )
    self:SetMaterial( self.ModelMaterial )

    self:PhysicsInitBox( -self.HullVec, self.HullVec )
    self:SetMoveType( MOVETYPE_FLYGRAVITY )
    self:SetCollisionGroup( COLLISION_GROUP_PROJECTILE )

    -- don't hit the world, frozen props until this much time has passed
    local nextHitTime = 0.5
    self.NextHitTime = CurTime() + nextHitTime

    timer.Simple( nextHitTime, function() -- so we can land back on the owner
        if not IsValid( self ) then return end
        self:SetOwner()
    end )
end

function ENT:PostHit( _hitEnt, pos, normal, _speed, _damageDealt, _actuallyDidDamage ) -- always runs when it hits something
    local effOne = EffectData()
    effOne:SetOrigin( pos )
    effOne:SetScale( 2 )
    effOne:SetRadius( 4 )
    effOne:SetNormal( normal )
    util.Effect( "StriderBlood", effOne )

    local effTwo = EffectData()
    effTwo:SetOrigin( pos )
    effTwo:SetScale( 1 )
    effTwo:SetRadius( 4 )
    effTwo:SetNormal( -normal )
    util.Effect( "StriderBlood", effTwo )

    local tomatEffec = EffectData()
    tomatEffec:SetOrigin( pos )
    tomatEffec:SetNormal( normal )
    tomatEffec:SetEntity( self )
    util.Effect( "cfc_tomato_decals", tomatEffec )

    self:EmitSound( "ambient/levels/canals/toxic_slime_gurgle7.wav", 70, 180, 1, CHAN_STATIC )
    self:EmitSound( "npc/antlion_grub/squashed.wav", 70, 180, 1, CHAN_STATIC )
end

function ENT:PostHitEnt( hitEnt, _damageDealt, actuallyDidDamage ) -- for doing something to whatever we hit, called inside PostEntityTakeDamage to respect hooks
    if not hitEnt:IsPlayer() then return end
    if not actuallyDidDamage then return end
    if self:WorldSpaceCenter():Distance( hitEnt:GetShootPos() ) > 30 then return end
    net.Start( "cfc_weapons_tomato_screentomato", false )
    net.Send( hitEnt )
end

function ENT:Touch( ent )
    if self.Projectile_Hit then return end
    if self:GetTouchTrace().HitSky then
        SafeRemoveEntity( self )
        return
    end

    if bit.band( ent:GetSolidFlags(), FSOLID_VOLUME_CONTENTS + FSOLID_TRIGGER ) > 0 then
        local takedamage = ent:GetSaveTable().m_takedamage

        if takedamage == 0 or takedamage == 1 then
            return
        end
    end

    local hitEnt = ent

    local normal = self:GetVelocity():GetNormalized()
    local pos = self:WorldSpaceCenter()

    local hitStaticTooEarly = self.NextHitTime > CurTime() and hitEnt:IsWorld() or ( IsValid( hitEnt:GetPhysicsObject() ) and not hitEnt:GetPhysicsObject():IsMotionEnabled() )

    -- only hit static stuff early IF it's directly in our way
    if hitStaticTooEarly and not util.QuickTrace( pos, normal * 25, self ).Hit then return end

    self.Projectile_Hit = true

    local attacker = IsValid( self:GetThrower() ) and self:GetThrower() or self:GetCreator()
    if not IsValid( attacker ) then
        attacker = self
    end

    local speed = self:GetVelocity():Length()

    local caughtDamage
    local damageDealt = 0
    local actuallyDidDamage = false
    local hookName = "cfc_throwable_projectile_damagecatch_" .. self:GetCreationID()

    -- do anything that needs to respect hooks, in PostHitEnt
    hook.Add( "PostEntityTakeDamage", hookName, function( victim, dmgInfo, took )
        local inflictor = dmgInfo:GetInflictor()
        if inflictor ~= self then return end
        hook.Remove( "PostEntityTakeDamage", hookName ) -- remove the hook so only gets called once
        caughtDamage = true
        damageDealt = dmgInfo:GetDamage()
        actuallyDidDamage = took
        self:PostHitEnt( victim, damageDealt, actuallyDidDamage )
    end )

    local damageSpeed = speed + -self.AdditionalDamageStartingVel
    damageSpeed = math.Clamp( damageSpeed, 0, math.huge )

    local damageAdded = damageSpeed / self.VelocityForOneDamage
    local force = self.BaseDamage * self.DamageForceMul * speed

    -- if the ent has npc/player hitbox properties, do a quick FireBullets to take advantage of it's headshot calculations
    if ent:IsPlayer() or ent:IsNPC() then
        local bulletTbl = {
            Attacker = attacker,
            Damage = self.BaseDamage + damageAdded,
            Force = force / 1000,
            HullSize = self.HullSize,
            Distance = 45,
            Num = 1,
            Tracer = 0,
            Dir = normal,
            Src = pos,
            IgnoreEntity = self,
            Callback = function( _, trResult, dmgInfo )
                if not trResult.Hit then return false, false end
                hitEnt = trResult.Entity
                damageDealt = dmgInfo:GetDamage()
                dmgInfo:SetDamageType( DMG_CLUB )
                return false, nil
            end
        }
        self:FireBullets( bulletTbl )

    end
    -- bullet missed, or hit a prop, just hit the ent for reduced damage
    if damageDealt == 0 then
        damageDealt = self.BaseDamage + damageAdded / 4
        local damageInfo = DamageInfo()
        damageInfo:SetDamageType( DMG_CLUB )
        damageInfo:SetAttacker( attacker )
        damageInfo:SetInflictor( self )
        damageInfo:SetDamagePosition( pos )
        damageInfo:SetDamage( damageDealt )
        damageInfo:SetDamageForce( normal * force )
        ent:TakeDamageInfo( damageInfo )
    end

    -- the PostEntityTakeDamage above has now called PostHitEnt, or it didn't

    if not IsValid( self ) then return end -- we were removed in PostHitEnt?

    if not caughtDamage then
        hook.Remove( "PostEntityTakeDamage", hookName ) -- just in case the damage never was dealt, remove the hook
    end

    self:PostHit( hitEnt, pos, normal, speed, damageDealt ) -- this is always called after a projectile hits, even if it never does damage

    SafeRemoveEntity( self )
end