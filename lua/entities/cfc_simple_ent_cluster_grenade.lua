AddCSLuaFile()

DEFINE_BASECLASS( "cfc_simple_ent_grenade_base" )

ENT.Base = "cfc_simple_ent_grenade_base"

ENT.Model = Model( "models/weapons/w_eq_fraggrenade.mdl" )

ENT.GrenadeParams = {
    Damage = 20,
    Radius = 200,
    ClusterAmount = 6,
    ClusterAmountMult = 0, -- Multiplier for the next grenade's split amount. Must be >= 0 and < 1.
    ExplodeOnSplit = false, -- Also make an explosion when splitting.
    SplitLimit = false, -- If provided as a number, then the number of splits will be capped by this amount, regardless of the cluster amount or mult.
    SplitSpeed = 300,
    SplitSpread = 60, -- 0 to 180
    SplitMoveAhead = 0,
    BaseVelMultOnImpact = 0.25,
    ExplosionPitch = 120,
}


local GIB_POS_TO_CENTER = Vector( 11.33175, 0, 0 ) -- The flakgib model has a messed up origin.
local GIB_MODEL = "models/props_phx/gibs/flakgib1.mdl"


function ENT:SetupDataTables()
    self:NetworkVar( "Bool", 0, "UseGibModel" )

    if CLIENT then
        self:NetworkVarNotify( "UseGibModel", function( ent, _, _, state )
            if state then
                ent:SetModel( GIB_MODEL )
                self:SetMaterial( "" )
            else
                ent:SetModel( ent.Model )
                self:SetMaterial( "models/weapons/w_models/cfc_frag_grenade/frag_grenade_cluster" )
            end
        end )
    end
end

function ENT:Initialize()
    BaseClass.Initialize( self )

    self:SetMaterial( "models/weapons/w_models/cfc_frag_grenade/frag_grenade_cluster" )

    if SERVER then
        -- A timer is needed to prevent :PhysicsCollide() from triggering on the sibling cluster grenades, as the collision group doesn't apply until the next tick.
        timer.Simple( 0, function()
            if not IsValid( self ) then return end

            local exploded = false

            function self:PhysicsCollide( colData )
                if exploded then return end

                exploded = true

                local hitNormal = -colData.HitNormal

                timer.Simple( 0, function()
                    if not IsValid( self ) then return end

                    self:Explode( hitNormal, self.GrenadeParams.BaseVelMultOnImpact )
                end )
            end
        end )
    else
        if self:GetUseGibModel() then
            self:SetModel( GIB_MODEL )
            self:SetMaterial( "" )
        end
    end
end

function ENT:Explode( splitDir, baseVelMult )
    local grenadeParams = self.GrenadeParams
    local clusterAmount = grenadeParams.ClusterAmount
    local splitLimit = grenadeParams.SplitLimit

    if splitLimit == 0 then
        clusterAmount = 0
    end

    -- Explode
    if clusterAmount == 0 or grenadeParams.ExplodeOnSplit then
        local pos = self:GetUseGibModel() and self:LocalToWorld( GIB_POS_TO_CENTER ) or self:WorldSpaceCenter()

        local dmgInfoInit = DamageInfo()
        dmgInfoInit:SetAttacker( self:GetOwner() )
        dmgInfoInit:SetInflictor( self )
        dmgInfoInit:SetDamage( grenadeParams.Damage )
        dmgInfoInit:SetDamageType( DMG_BLAST )

        local class = self:GetClass()

        CFCPvPWeapons.BlastDamageInfo( dmgInfoInit, pos, grenadeParams.Radius, function( victim )
            if victim == self then return true end
            if not IsValid( victim ) then return end
            if victim:GetClass() == class then return true end -- Don't damage other cluster grenades
        end )

        local effect = EffectData()
        effect:SetStart( pos )
        effect:SetOrigin( pos )
        effect:SetFlags( 4 + 64 + 128 )

        util.Effect( "Explosion", effect, true, true )
        sound.Play( "weapons/explode" .. math.random( 3, 5 ) .. ".wav", pos, 130, grenadeParams.ExplosionPitch, 0.25 )

        if clusterAmount == 0 then
            self:Remove()
            return
        end
    end

    -- Split
    local pos = self:WorldSpaceCenter()
    local owner = self:GetOwner()
    local baseVel = self:GetVelocity()

    if not splitDir then
        local baseSpeed = baseVel:Length()

        if baseSpeed < 10 then
            splitDir = Vector( 0, 0, 0 )
        else
            splitDir = baseVel / baseSpeed
        end
    end

    if baseVelMult then
        baseVel = baseVel * baseVelMult
    end

    local splitSpeed = grenadeParams.SplitSpeed
    local splitSpread = grenadeParams.SplitSpread
    local splitMoveAhead = grenadeParams.SplitMoveAhead
    local explodeDelay = self._explodeDelay
    local class = self:GetClass()
    local nextClusterAmount = math.floor( clusterAmount * grenadeParams.ClusterAmountMult )

    splitLimit = splitLimit and splitLimit - 1

    for _ = 1, clusterAmount do
        local dir = CFCPvPWeapons.SpreadDir( splitDir, splitSpread )

        local ent = ents.Create( class )
        ent:SetPos( pos + dir * splitMoveAhead )
        ent:SetAngles( dir:Angle() )
        ent:SetOwner( owner )
        ent:Spawn()

        ent:SetUseGibModel( true )
        ent:SetModel( GIB_MODEL )
        ent:SetMaterial( "" )
        ent:PhysicsInit( SOLID_VPHYSICS )

        local physObj = ent:GetPhysicsObject()

        ent:SetCollisionGroup( COLLISION_GROUP_INTERACTIVE_DEBRIS )
        physObj:AddGameFlag( FVPHYSICS_NO_IMPACT_DMG )
        physObj:AddGameFlag( FVPHYSICS_NO_NPC_IMPACT_DMG )
        physObj:SetVelocity( dir * splitSpeed + baseVel )

        local entGrenadeParams = ent.GrenadeParams

        -- Copy the grenade params
        for k, v in pairs( grenadeParams ) do
            entGrenadeParams[k] = v
        end

        entGrenadeParams.ClusterAmount = nextClusterAmount
        entGrenadeParams.SplitLimit = splitLimit

        if explodeDelay and nextClusterAmount ~= 0 and splitLimit ~= 0 then
            ent:SetTimer( explodeDelay )
        end
    end

    --sound.Play( "phx/epicmetal_hard5.wav", pos, 75, 100 ) -- Directionless sound :(
    sound.Play( "weapons/crossbow/fire1.wav", pos, 85, 135 )
    sound.Play( "weapons/crossbow/hit1.wav", pos, 85, 135 )

    self:Remove()
end
