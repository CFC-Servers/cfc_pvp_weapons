AddCSLuaFile()

ENT.Base = "base_anim"
ENT.Type = "anim"

ENT.AutomaticFrameAdvance = true

ENT.Model = Model( "models/weapons/w_npcnade.mdl" )

ENT.BeepEnabled = true
ENT.BeepDelay = 1
ENT.BeepDelayFast = 0.3
ENT.BeepFastThreshold = 1.5


function ENT:SetTimer( delay )
    self._explodeTime = CurTime() + delay
    self._explodeDelay = delay

    if self.BeepEnabled then
        self._nextBeepTime = CurTime()
    end

    self:NextThink( CurTime() )
end

function ENT:Initialize()
    self:SetModel( self.Model )

    if SERVER then
        self:PhysicsInit( SOLID_VPHYSICS )
        self:SetMoveType( MOVETYPE_VPHYSICS )
        self:SetSolid( SOLID_VPHYSICS )

        self:SetCollisionGroup( COLLISION_GROUP_PROJECTILE )
        self:GetPhysicsObject():AddGameFlag( FVPHYSICS_NO_IMPACT_DMG )
        self:GetPhysicsObject():AddGameFlag( FVPHYSICS_NO_NPC_IMPACT_DMG )

        local phys = self:GetPhysicsObject()

        if IsValid( phys ) then
            phys:Wake()
            phys:SetMass( 5 ) -- Heavy enough to break windows
        end
    end
end

function ENT:ACF_PreDamage()
    return false
end

function ENT:Explode()
    self:Remove()
end

function ENT:Think()
    if CLIENT then return end

    self:BeepThink()

    if self._explodeTime and self._explodeTime <= CurTime() then
        self:Explode()
        self:NextThink( math.huge )

        return true
    end

    self:NextThink( CurTime() + 0.1 )

    return true
end

function ENT:BeepThink()
    local nextBeepTime = self._nextBeepTime
    if not nextBeepTime then return end

    local now = CurTime()
    if nextBeepTime > now then return end

    self:PlayBeep()

    local delay
    local explodeTime = self._explodeTime

    if explodeTime and explodeTime - now <= self.BeepFastThreshold then
        delay = self.BeepDelayFast
    else
        delay = self.BeepDelay
    end

    self._nextBeepTime = now + delay
end


----- OVERRIDABLE FUNCTIONS -----

function ENT:PlayBeep()
    self:EmitSound( "Grenade.Blip" )
end
