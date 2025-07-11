AddCSLuaFile()

DEFINE_BASECLASS( "cfc_simple_ent_grenade_base" )

ENT.Base = "cfc_simple_ent_grenade_base"

ENT.Model = Model( "models/weapons/w_npcnade.mdl" )

ENT.BeepEnabled = true
ENT.BeepDelay = 1
ENT.BeepDelayFast = 0.3
ENT.BeepFastThreshold = 1.5

ENT.Damage = 100


function ENT:Initialize()
    BaseClass.Initialize( self )

    if SERVER then
        local attachment = self:LookupAttachment( "fuse" )

        if attachment <= 0 then
            return
        end

        local pos = self:GetAttachment( attachment ).Pos

        local main = ents.Create( "env_sprite" )

        main:SetPos( pos )
        main:SetParent( self )
        main:SetKeyValue( "model", "sprites/redglow1.vmt" )
        main:SetKeyValue( "scale", 0.2 )
        main:SetKeyValue( "GlowProxySize", 4 )
        main:SetKeyValue( "rendermode", 5 )
        main:SetKeyValue( "renderamt", 200 )
        main:Spawn()
        main:Activate()

        local trail = ents.Create( "env_spritetrail" )

        trail:SetPos( pos )
        trail:SetParent( self )
        trail:SetKeyValue( "spritename", "sprites/bluelaser1.vmt" )
        trail:SetKeyValue( "startwidth", 8 )
        trail:SetKeyValue( "endwidth", 1 )
        trail:SetKeyValue( "lifetime", 0.5 )
        trail:SetKeyValue( "rendermode", 5 )
        trail:SetKeyValue( "rendercolor", "255 0 0" )
        trail:Spawn()
        trail:Activate()

        self:DeleteOnRemove( main )
        self:DeleteOnRemove( trail )
    end
end

function ENT:Explode()
    local pos = self:WorldSpaceCenter()

    local explo = ents.Create( "env_explosion" )
    explo:SetOwner( self:GetOwner() )
    explo:SetPos( pos )
    explo:SetKeyValue( "iMagnitude", self.Damage )
    explo:SetKeyValue( "spawnflags", 32 )
    explo:Spawn()
    explo:Activate()
    explo:Fire( "Explode" )

    self:Remove()
end

function ENT:PlayBeep()
    self:EmitSound( "Grenade.Blip" )
end
