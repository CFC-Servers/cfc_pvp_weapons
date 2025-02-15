AddCSLuaFile()

ENT.Type = "anim"

function ENT:SetupDataTables()
    self:NetworkVar( "Bool", 0, "Disabled" )
    self:NetworkVar( "Bool", 1, "CleanMissile" )
    self:NetworkVar( "Bool", 2, "DirtyMissile" )
    self:NetworkVar( "Bool", 3, "HasTarget" ) -- glide lockon handler
    self:NetworkVar( "Entity", 0, "Attacker" )
    self:NetworkVar( "Entity", 1, "Inflictor" )
    self:NetworkVar( "Entity", 2, "LockOn" )

    if not SERVER then return end

    self:NetworkVarNotify( "LockOn", self.OnLockOnChange )
end

if SERVER then
    function ENT:OnLockOnChange( _, _, new )
        self:SetHasTarget( IsValid( new ) )
    end

    local stingerDmgMulCVar = CreateConVar( "cfc_stinger_damage_mul", 1, FCVAR_ARCHIVE )
    local stingerMobilityMulCVar = CreateConVar( "cfc_stinger_mobility_mul", 1, FCVAR_ARCHIVE )
    local stingerDirectHitPlayerMulCVar = CreateConVar( "cfc_stinger_direct_hit_players_mul", 1, FCVAR_ARCHIVE )

    local MISSILE_HITBOX_MAXS = Vector( 10, 10, 10 )
    local MISSILE_HITBOX_MINS = -MISSILE_HITBOX_MAXS
    local MISSILE_HITTRACE_DIST = 20

    local BLAST_DAMAGE = 150
    local BLAST_RADIUS = 200
    local DIRECTHIT_GENERIC_DAMAGE = 700
    local DIRECTHIT_CAR_DAMAGE = 1250
    local DIRECTHIT_NPC_DAMAGE = 200
    local DIRECTHIT_PLAYER_DAMAGE = 70 -- ends up getting added with the blastdamage, doesn't need to be too strong

    local BLINDFIRE_MAXSPEED_TIME = 1.5
    local BLIND_STABILITY_AT_MAXSPEED = 0.25
    local BLIND_STABILITY_BEFORE_MAXSPEED = 0.10
    local BLINDFIRE_ANGVEL_DECAY = 0.98
    local MAX_BLINDFIRE_SPEED = 3000

    local LOCKED_TURNRATE_ADDED_PER_SECOND_ALIVE = 45
    local LOCKED_SPEED_ADDED_PER_SECOND_ALIVE = 500
    local LOCKED_MAX_TURNRATE_ADDED = 400
    local LOCKED_MAX_SPEED_ADDED = 10000
    local LOCKED_DEFAULT_SPEED = 1500
    local LOCKED_DEFAULT_TURNRATE = 20
    local LOCKED_TARGET_LEAD_MUL = 0.15
    local LOCKED_LOSE_TARGET_ANG = 50
    local LOCKED_START_CHECKING_TRACES_DIST = 750^2
    local LOCKED_DETONATE_ANYWAYS_DIST = 75^2

    local GLIDE_FLARE_YIELD_RADIUS = 1150 -- glide homing missiles are 1500 dist

    local GetClosestFlare
    if Glide then
        GetClosestFlare = Glide.GetClosestFlare
    end

    sound.Add( {
        name = "cfc_stinger_impactflesh",
        channel = CHAN_STATIC,
        volume = 1.0,
        level = 130,
        pitch = { 90, 100 },
        sound = {
            "physics/flesh/flesh_squishy_impact_hard1.wav",
            "physics/flesh/flesh_squishy_impact_hard2.wav",
            "physics/flesh/flesh_squishy_impact_hard3.wav",
            "physics/flesh/flesh_squishy_impact_hard4.wav"
        }
    } )

    function ENT:SpawnFunction( _, tr, className )
        if not tr.Hit then return end

        local ent = ents.Create( className )
        ent:SetPos( tr.HitPos + tr.HitNormal * 20 )
        ent:Spawn()
        ent:Activate()

        return ent
    end

    function ENT:BlindFire()
        if self:DoHitTrace() then return end -- we hit something

        local pObj = self:GetPhysicsObject()
        if not IsValid( pObj ) then return end

        -- ramp up to full speed over a bit less than 1 second
        local timeAlive = math.abs( self:GetCreationTime() - CurTime() )
        local tillFullSpeed = timeAlive / BLINDFIRE_MAXSPEED_TIME

        local instability
        if tillFullSpeed >= 1 then -- drift a LOT once we get to max speed
            instability = BLIND_STABILITY_AT_MAXSPEED
        else
            instability = BLIND_STABILITY_BEFORE_MAXSPEED
        end

        local speed = math.Clamp( tillFullSpeed * MAX_BLINDFIRE_SPEED, 0, MAX_BLINDFIRE_SPEED )
        local vel = ( speed * stingerMobilityMulCVar:GetFloat() )
        pObj:SetVelocityInstantaneous( self:GetForward() * vel )

        local angVel = pObj:GetAngleVelocity() * BLINDFIRE_ANGVEL_DECAY -- bias towards going straight, spiral out of turns
        angVel = angVel + VectorRand() * instability -- but not too straight

        pObj:SetAngleVelocity( angVel )
    end

    function ENT:FollowTarget( followEnt )
        local pObj = self:GetPhysicsObject()
        if not IsValid( pObj ) then return end

        -- increase turnrate the longer missile is alive, bear down on far targets.
        -- goal is to punish pilots/drivers who camp far away from players.
        local mobilMul = stingerMobilityMulCVar:GetFloat()
        local timeAlive = math.abs( self:GetCreationTime() - CurTime() )
        local turnrateAdd = math.Clamp( timeAlive * LOCKED_TURNRATE_ADDED_PER_SECOND_ALIVE, 0, LOCKED_MAX_TURNRATE_ADDED ) * mobilMul
        local speedAdd = math.Clamp( timeAlive * LOCKED_SPEED_ADDED_PER_SECOND_ALIVE, 0, LOCKED_MAX_SPEED_ADDED ) * mobilMul

        local speed = LOCKED_DEFAULT_SPEED
        speed = speed + speedAdd

        local turnrate = LOCKED_DEFAULT_TURNRATE
        turnrate = turnrate + turnrateAdd

        local parent = followEnt:GetParent()
        if IsValid( parent ) and parent:IsVehicle() then -- glide vehicle fix
            followEnt = parent
        end

        local myPos = self:GetPos()
        local targetPos

        if GetClosestFlare then -- glide flares do something
            local flare = GetClosestFlare( myPos, self:GetForward(), GLIDE_FLARE_YIELD_RADIUS )
            if IsValid( flare ) then
                targetPos = flare:WorldSpaceCenter()
            end
        end

        if not targetPos then
            if isfunction( followEnt.GetMissileOffset ) then
                local value = followEnt:GetMissileOffset()
                if isvector( value ) then
                    targetPos = followEnt:LocalToWorld( value )
                end
            else
                targetPos = followEnt:WorldSpaceCenter()
            end
        end

        targetPos = targetPos + followEnt:GetVelocity() * LOCKED_TARGET_LEAD_MUL

        local subtractionProduct = targetPos - myPos
        local distToTargSqr = subtractionProduct:LengthSqr()
        local targetdir = subtractionProduct:GetNormalized()

        local AF = self:WorldToLocalAngles( targetdir:Angle() )
        local badAngles = AF.p > LOCKED_LOSE_TARGET_ANG or AF.y > LOCKED_LOSE_TARGET_ANG

        -- if you want to make a plane/vehicle not get targeted by the launcher then see CFC_Stinger_BlockLockon hook, in the launcher

        if distToTargSqr < LOCKED_START_CHECKING_TRACES_DIST and self:DoHitTrace( myPos ) then -- close to target, start doing traces in front of us
            return
        -- target is cheating! they're no collided!
        elseif distToTargSqr < LOCKED_DETONATE_ANYWAYS_DIST then
            self:HitEntity( followEnt )
            return
        -- target escaped!
        elseif badAngles then
            self:SetLockOn( nil )
            return
        end

        AF.p = math.Clamp( AF.p * 400, -turnrate, turnrate )
        AF.y = math.Clamp( AF.y * 400, -turnrate, turnrate )
        AF.r = math.Clamp( AF.r * 400, -turnrate, turnrate )

        local AVel = pObj:GetAngleVelocity()
        pObj:AddAngleVelocity( Vector( AF.r, AF.p, AF.y ) - AVel )

        pObj:SetVelocityInstantaneous( self:GetForward() * speed )
    end

    function ENT:Initialize()
        self:SetModel( "models/weapons/w_missile_launch.mdl" )
        self:PhysicsInit( SOLID_VPHYSICS )
        self:SetMoveType( MOVETYPE_VPHYSICS )
        self:SetSolid( SOLID_VPHYSICS )
        self:SetRenderMode( RENDERMODE_TRANSALPHA )
        self:PhysWake()
        local pObj = self:GetPhysicsObject()

        if IsValid( pObj ) then
            pObj:EnableGravity( false )
            pObj:SetMass( 1 )
        end

        self.SpawnTime = CurTime()
    end

    function ENT:Think()
        local curtime = CurTime()
        self:NextThink( curtime )

        local target = self:GetLockOn()
        if not self:GetDisabled() and IsValid( target ) then
            if not self.DoneMissileDanger then
                self:HandleMissileDanger( target )
            end

            self:FollowTarget( target )
        else
            self:BlindFire()
        end

        if ( self.SpawnTime + 12 ) < curtime then
            self:Detonate()
        end

        return true
    end

    function ENT:PhysicsCollide( data )
        if self:GetDisabled() then
            self:Detonate()
        else
            local hitEnt = data.HitEntity

            self:HitEntity( hitEnt )
        end
    end

    function ENT:DoHitTrace( myPos )
        local startPos = myPos or self:GetPos()
        local offset = self:GetForward() * MISSILE_HITTRACE_DIST
        local inflic = self:GetInflictor()

        local trResult = util.TraceHull( {
            start = startPos,
            endpos = startPos + offset,
            filter = { self, self:GetOwner(), inflic },
            maxs = MISSILE_HITBOX_MAXS,
            mins = MISSILE_HITBOX_MINS,
            mask = MASK_SOLID,
        } )

        if trResult.Hit then
            -- dont hit sub-ents of the inflictor
            if IsValid( inflic ) and IsValid( trResult.Entity:GetParent() ) and trResult.Entity:GetParent() == inflic then return end
            self:HitEntity( trResult.Entity )
            return true
        end
    end

    function ENT:GetDirectHitDamage( hitEnt )
        local hookResultDmg, hookResultSound = hook.Run( "LFS.MissileDirectHitDamage", self, hitEnt )
        if hookResultDmg ~= nil and isnumber( hookResultDmg ) then return hookResultDmg, hookResultSound end

        local dmgAmount = DIRECTHIT_GENERIC_DAMAGE
        local dmgSound = "Missile.ShotDown"

        if hitEnt.IsSimfphyscar then
            dmgAmount = DIRECTHIT_CAR_DAMAGE
        elseif hitEnt:IsNPC() or hitEnt:IsNextBot() then
            dmgAmount = DIRECTHIT_NPC_DAMAGE
            local obj = hitEnt:GetPhysicsObject()
            if IsValid( obj ) and obj:GetMaterial() and not string.find( obj:GetMaterial(), "metal" ) then
                dmgSound = "cfc_stinger_impactflesh"
            end
        elseif hitEnt:IsPlayer() then
            dmgAmount = DIRECTHIT_PLAYER_DAMAGE * stingerDirectHitPlayerMulCVar:GetFloat()
            dmgSound = "cfc_stinger_impactflesh"
        end

        return dmgAmount, dmgSound
    end

    function ENT:HitEntity( hitEnt )
        if not IsValid( hitEnt ) then
            self:Detonate() -- hit world
            return

        end

        local Pos = self:GetPos()
        -- hit simfphys car instead of simfphys wheel
        if hitEnt.GetBaseEnt and IsValid( hitEnt:GetBaseEnt() ) then
            hitEnt = hitEnt:GetBaseEnt()
        end

        local effectdata = EffectData()
            effectdata:SetOrigin( Pos )
            effectdata:SetNormal( -self:GetForward() )
        util.Effect( "manhacksparks", effectdata, true, true )

        local dmgAmount, dmgSound = self:GetDirectHitDamage( hitEnt )
        dmgAmount = dmgAmount * stingerDmgMulCVar:GetFloat()

        local dmginfo = DamageInfo()
            dmginfo:SetDamage( dmgAmount )
            dmginfo:SetAttacker( IsValid( self:GetAttacker() ) and self:GetAttacker() or self )
            dmginfo:SetDamageType( DMG_DIRECT )
            dmginfo:SetInflictor( self )
            dmginfo:SetDamagePosition( Pos )
            dmginfo:SetDamageForce( self:GetForward() * dmgAmount * 500 )
        hitEnt:TakeDamageInfo( dmginfo )

        sound.Play( dmgSound, Pos, 140 )

        self:Detonate()
    end

    function ENT:BreakMissile()
        if not self:GetDisabled() then
            self:SetDisabled( true )

            local pObj = self:GetPhysicsObject()

            if IsValid( pObj ) then
                pObj:EnableGravity( true )
                self:PhysWake()
                self:EmitSound( "Missile.ShotDown" )
            end
        end
    end

    function ENT:Detonate()
        local dmgMul = stingerDmgMulCVar:GetFloat()
        local inflictor = self:GetInflictor()
        local attacker = self:GetAttacker()
        local explodePos = self:WorldSpaceCenter()

        local effectdata = EffectData()
            effectdata:SetOrigin( self:GetPos() )
        util.Effect( "Explosion", effectdata )

        self:EmitSound( "vehicles/airboat/pontoon_impact_hard1.wav", 100, 50, 0.5 )
        self:EmitSound( "Explo.ww2bomb" )

        self:Remove()

        timer.Simple( 0, function()
            local fallbackDamager = Entity( 0 )
            inflictor = IsValid( inflictor ) and inflictor or fallbackDamager
            attacker = IsValid( attacker ) and attacker or fallbackDamager

            util.BlastDamage( inflictor, attacker, explodePos, BLAST_RADIUS * dmgMul, BLAST_DAMAGE * dmgMul )
        end )
    end

    function ENT:OnTakeDamage( dmginfo )
        if not dmginfo:IsDamageType( DMG_AIRBOAT ) then return end
        if self:GetAttacker() == dmginfo:GetAttacker() then return end

        self:BreakMissile()
    end

    function ENT:HandleMissileDanger( target )
        if not Glide then return end

        -- Let Glide vehicles know about this missile
        if target.IsGlideVehicle then
            Glide.SendMissileDanger( target:GetAllPlayers(), self )

        -- Let players in seats know about this missile
        elseif target:IsVehicle() then
            local driver = target:GetDriver()

            if IsValid( driver ) then
                Glide.SendMissileDanger( driver, self )
            end
        end
    end

else -- client
    function ENT:Initialize()
        self.snd = CreateSound( self, "weapons/flaregun/burn.wav" )
        self.snd:SetSoundLevel( 90 )
        self.snd:Play()

        -- make trail effect on client init
        -- very very unreliable on server init
        local effectdata = EffectData()
            effectdata:SetOrigin( self:GetPos() )
            effectdata:SetEntity( self )
        util.Effect( "cfc_stinger_trail", effectdata, true, true )

        self:SetHasTarget( true ) -- glide lockon sound hack that styled recommended
    end

    function ENT:Draw()
        self:DrawModel()
    end

    function ENT:SoundStop()
        if self.snd then
            self.snd:Stop()
        end
    end

    function ENT:Think()
        if self:GetDisabled() then
            self:SoundStop()
        end

        return true
    end

    function ENT:OnRemove()
        self:SoundStop()
    end
end