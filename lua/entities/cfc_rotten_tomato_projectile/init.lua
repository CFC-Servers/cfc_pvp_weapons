AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
include( "shared.lua" )

util.AddNetworkString( "cfc_weapons_tomato_screentomato" )

function ENT:Initialize()
    self:SetModel( self.Model )
    self:SetMaterial( self.ModelMaterial )

    self:DoFlyingSound()
    self:PhysicsInitBox( -self.HullVec, self.HullVec )
    self:SetMoveType( MOVETYPE_FLYGRAVITY )
    self:SetCollisionGroup( COLLISION_GROUP_PROJECTILE )

    -- don't hit the world, frozen props until this much time has passed
    self.NextHitTime = CurTime() + 0.5
end

function ENT:HitEffects( pos, normal, _ ) -- pos, normal, speed
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

function ENT:PostHitEnt( hitEnt )
    if not hitEnt:IsPlayer() then return end
    if hook.Run( "cfc_weapons_tomato_blockblinding", hitEnt, self ) == true then return end
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

    local attacker = self:GetOwner()
    if not IsValid( attacker ) then
        attacker = self

    end

    local speed = self:GetVelocity():Length()

    self:HitEffects( pos, normal, speed )

    local damageSpeed = speed + -self.AdditionalDamageStartingVel
    damageSpeed = math.Clamp( damageSpeed, 0, math.huge )

    local damageAdded = damageSpeed / self.VelocityForOneDamage
    local damageDealt = 0
    local force = self.BaseDamage * speed

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

    self:PostHitEnt( hitEnt, damageDealt )

    SafeRemoveEntity( self )
end

local airSoundPath = "ambient/levels/canals/windmill_wind_loop1.wav"

function ENT:DoFlyingSound()
    local filterAll = RecipientFilter()
    filterAll:AddPVS( self:GetPos() )

    local airSound = CreateSound( self, airSoundPath, filterAll )
    self.airSound = airSound
    airSound:SetSoundLevel( 70 )
    airSound:Play()

    local timerName = "cfc_tomato_whistle_sound_" .. self:GetCreationID()

    local StopAirSound = function()
        timer.Remove( timerName )
        if not IsValid( self ) then return end
        self.airSound:Stop()
        self.airSound = nil

    end

    self:CallOnRemove( "cfc_tomato_whistle_stop", function() StopAirSound() end )

    -- change pitch/vol
    timer.Create( timerName, 0, 0, function()
        if not IsValid( self ) then StopAirSound() return end
        if not airSound:IsPlaying() then StopAirSound() return end
        local vel = self:GetVelocity():Length()
        local pitch = vel / 8
        local volume = vel / 1500
        airSound:ChangePitch( pitch )
        airSound:ChangeVolume( volume )
    end )
end