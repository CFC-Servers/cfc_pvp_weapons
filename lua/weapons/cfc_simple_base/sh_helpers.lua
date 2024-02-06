AddCSLuaFile()

function SWEP:HasCameraControl()
    local ply = self:GetOwner()

    if CLIENT and not ply:ShouldDrawLocalPlayer() then
        return true
    end

    return ply:GetViewEntity() == ply
end

function SWEP:GetOwnerDefaultFOV()
    return self:GetOwner():GetInfoNum( "fov_desired", 75 )
end

function SWEP:GetTargetFOV()
    local zoom = self:GetZoom()

    if zoom == 1 then
        return 0
    end

    return self:GetOwnerDefaultFOV() / self:GetZoom()
end

function SWEP:UpdateFOV( time )
    self:GetOwner():SetFOV( self:GetTargetFOV(), time, self )
end

function SWEP:GetFOV()
    return self:GetOwner():GetFOV()
end

function SWEP:GetViewModel( _index )
    return self:GetOwner():GetViewModel()
end

function SWEP:GetShootDir()
    local ply = self:GetOwner()

    if ply:IsNPC() then
        return ply:GetAimVector()
    else
        return ( ply:GetAimVector():Angle() + ply:GetViewPunchAngles() ):Forward()
    end
end

function SWEP:IsAltFireHeld()
    local ply = self:GetOwner()

    if not IsValid( ply ) or ply:IsNPC() then
        return false
    end

    return ply:KeyDown( IN_ATTACK2 )
end

function SWEP:ForceStopFire()
    local ply = self:GetOwner()

    if not IsValid( ply ) or not ply:IsPlayer() then
        return
    end

    ply:ConCommand( "-attack" )
end

function SWEP:DoAR2Impact( tr )
    if tr.HitSky then
        return
    end

    if not game.SinglePlayer() and not IsFirstTimePredicted() then
        return
    end

    local effect = EffectData()

    effect:SetOrigin( tr.HitPos + tr.HitNormal )
    effect:SetNormal( tr.HitNormal )

    util.Effect( "AR2Impact", effect )
end
