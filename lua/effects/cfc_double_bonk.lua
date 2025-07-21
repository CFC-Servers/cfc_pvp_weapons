function EFFECT:Init( data )
    local localPos = data:GetOrigin() -- local if an entity is supplied, worldspace otherwise.
    local size = data:GetRadius() * 2
    local ent = data:GetEntity()
    ent = IsValid( ent ) and ent or nil

    local pos = IsValid( ent ) and ent:LocalToWorld( localPos ) or localPos
    local emitter = ParticleEmitter( pos )

    local particle = emitter:Add( "cfc_pvp_weapons/sprites/double_bonk", pos )
    particle:SetDieTime( 2.5 )
    particle:SetStartAlpha( 255 )
    particle:SetEndAlpha( 0 )
    particle:SetStartSize( size )
    particle:SetEndSize( size )

    self._ent = ent
    self._localPos = localPos
    self._emitter = emitter
    self._particle = particle
end

function EFFECT:Think()
    local ent = self._ent
    local emitter = self._emitter

    if not IsValid( ent ) or emitter:GetNumActiveParticles() == 0 or ( ent.Alive and not ent:Alive() ) then
        emitter:Finish()
        return false
    end

    local pos

    if ent == LocalPlayer() then
        pos = ent:GetPos() + self._localPos
    else
        pos = ent:LocalToWorld( self._localPos )
    end

    local particle = self._particle

    particle:SetPos( pos )

    return true
end

function EFFECT:Render()
end