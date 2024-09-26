AddCSLuaFile()

DEFINE_BASECLASS( "cfc_simple_ent_grenade_base" )

ENT.Base = "cfc_simple_ent_grenade_base"

ENT.Model = Model( "models/weapons/w_eq_fraggrenade.mdl" )

ENT.Damage = 20
ENT.Radius = 200
ENT.ClusterAmount = 6
ENT.SplitSpeed = 300
ENT.SplitSpread = 60 -- 0 to 180
ENT.SplitMoveAhead = 0
ENT.BaseVelMultOnImpact = 0.25


local GIB_POS_TO_CENTER = Vector( 11.33175, 0, 0 ) -- The flakgib model has a messed up origin.
local GIB_MODEL = "models/props_phx/gibs/flakgib1.mdl"


function ENT:SetupDataTables()
    self:NetworkVar( "Bool", 0, "NoMoreSplits" )

    if CLIENT then
        self:NetworkVarNotify( "NoMoreSplits", function( ent, _, _, state )
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
        timer.Simple( 0, function()
            if not IsValid( self ) then return end

            local exploded = false

            function self:PhysicsCollide( colData )
                if exploded then return end

                exploded = true

                local hitNormal = -colData.HitNormal

                timer.Simple( 0, function()
                    if not IsValid( self ) then return end

                    self:Explode( hitNormal, self.BaseVelMultOnImpact )
                end )
            end
        end )
    else
        if self:GetNoMoreSplits() then
            self:SetModel( GIB_MODEL )
            self:SetMaterial( "" )
        end
    end
end

function ENT:Explode( splitDir, baseVelMult )
    local clusterAmount = self.ClusterAmount

    -- Explode
    if clusterAmount == 0 then
        local pos = self:LocalToWorld( GIB_POS_TO_CENTER )

        local dmgInfoInit = DamageInfo()
        dmgInfoInit:SetAttacker( self:GetOwner() )
        dmgInfoInit:SetInflictor( self )
        dmgInfoInit:SetDamage( self.Damage )
        dmgInfoInit:SetDamageType( DMG_BLAST )

        local class = self:GetClass()

        CFCPvPWeapons.BlastDamageInfo( dmgInfoInit, pos, self.Radius, function( victim )
            if victim == self then return true end
            if not IsValid( victim ) then return end
            if victim:GetClass() == class then return true end -- Don't damage other cluster grenades
        end )

        local effect = EffectData()
        effect:SetStart( pos )
        effect:SetOrigin( pos )
        effect:SetFlags( 4 + 64 + 128 )

        util.Effect( "Explosion", effect, true, true )
        sound.Play( "weapons/explode" .. math.random( 3, 5 ) .. ".wav", pos, 130, 120, 0.25 )

        self:Remove()

        return
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

    local splitSpeed = self.SplitSpeed
    local splitSpread = self.SplitSpread
    local splitMoveAhead = self.SplitMoveAhead
    local class = self:GetClass()

    for _ = 1, clusterAmount do
        local dir = CFCPvPWeapons.SpreadDir( splitDir, splitSpread )

        local ent = ents.Create( class )
        ent:SetPos( pos + dir * splitMoveAhead )
        ent:SetAngles( dir:Angle() )
        ent:SetOwner( owner )
        ent:Spawn()

        ent:SetNoMoreSplits( true )

        ent:SetModel( GIB_MODEL )
        ent:SetMaterial( "" )
        ent:PhysicsInit( SOLID_VPHYSICS )

        ent:SetCollisionGroup( COLLISION_GROUP_INTERACTIVE_DEBRIS )
        ent:GetPhysicsObject():AddGameFlag( FVPHYSICS_NO_IMPACT_DMG )
        ent:GetPhysicsObject():AddGameFlag( FVPHYSICS_NO_NPC_IMPACT_DMG )

        ent.ClusterAmount = 0

        -- Funny mode
        --ent.ClusterAmount = math.floor( clusterAmount / 2 )
        --if self._explodeTime and ent.ClusterAmount ~= 0 then ent:SetTimer( 0.25 ) end

        local physObj = ent:GetPhysicsObject()
        physObj:SetVelocity( dir * splitSpeed + baseVel )
    end

    sound.Play( "phx/epicmetal_hard5.wav", pos, 75, 100 )

    self:Remove()
end
