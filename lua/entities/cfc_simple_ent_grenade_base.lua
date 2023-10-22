-- Credits to https://github.com/TankNut/simple-weapons

AddCSLuaFile()
ENT.Base = "base_anim"
ENT.Type = "anim"
ENT.AutomaticFrameAdvance = true

ENT.Model = Model( "models/weapons/w_npcnade.mdl" )
ENT.ExplodeTime = 3
ENT.Exploded = false
ENT.Beep = 0
ENT.BeepSound = Sound( "Grenade.Blip" )
ENT.Trail = false
ENT.TrailColor = "0 0 0"
ENT.TrailMaterial = "sprites/laser.vmt"
ENT.SpriteMaterial = "sprites/animglow01.vmt"

local SERVER = SERVER

function ENT:Initialize()
    self:SetModel( self.Model )
    self.Detonate = CurTime() + self.ExplodeTime

    self:AddFlags( FL_GRENADE )
    self:AddFlags( FL_ONFIRE )

    if SERVER then
        self:PhysicsInit( SOLID_VPHYSICS )
        self:SetMoveType( MOVETYPE_VPHYSICS )
        self:SetSolid( SOLID_VPHYSICS )
        self:SetCollisionGroup( COLLISION_GROUP_WEAPON )
        local phys = self:GetPhysicsObject()
        if IsValid( phys ) then
            phys:Wake()
            phys:SetMass( 5 )
        end

        if self.Trail then
            local attachment = self:LookupAttachment( "fuse" )
            if attachment <= 0 then return end

            local pos = self:GetAttachment( attachment ).Pos

            local main = ents.Create( "env_sprite" )
            main:SetPos( pos )
            main:SetParent( self )
            main:SetKeyValue( "model", self.SpriteMaterial )
            main:SetKeyValue( "scale", 0.2 )
            main:SetKeyValue( "GlowProxySize", 4 )
            main:SetKeyValue( "rendermode", 5 )
            main:SetKeyValue( "renderamt", 200 )
            main:SetKeyValue( "rendercolor", self.TrailColor )
            main:Spawn()
            main:Activate()
            self.Main = main

            local trail = ents.Create( "env_spritetrail" )
            trail:SetPos( pos )
            trail:SetParent( self )
            trail:SetKeyValue( "spritename", self.TrailMaterial )
            trail:SetKeyValue( "startwidth", 8 )
            trail:SetKeyValue( "endwidth", 1 )
            trail:SetKeyValue( "lifetime", 0.5 )
            trail:SetKeyValue( "rendermode", 5 )
            trail:SetKeyValue( "rendercolor", self.TrailColor )
            trail:Spawn()
            trail:Activate()
            self.Trail = trail

            self:DeleteOnRemove( main )
            self:DeleteOnRemove( trail )
        end
    end
end

function ENT:Explode()
    self:Remove()
end

function ENT:Think()
    if SERVER and not self.Exploded and self.Beep and self.Beep <= CurTime() then
        self:EmitSound( self.BeepSound )
        local time = 1
        if self.Detonate and self.Detonate - CurTime() <= 1.5 then
            time = 0.3
        end

        self.Beep = CurTime() + time
    end

    if SERVER and not self.Exploded and self.Detonate and self.Detonate <= CurTime() then
        self.Exploded = true
        self:Explode()
    end

    self:NextThink( CurTime() + 0.1 )

    return true
end

function ENT:UpdateTransmitState()
    return TRANSMIT_ALWAYS
end
