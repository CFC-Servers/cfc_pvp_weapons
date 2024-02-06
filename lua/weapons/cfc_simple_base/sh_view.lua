AddCSLuaFile()

DEFINE_BASECLASS( "weapon_base" )

cfc_simple_weapons.Include( "Convars" )

function SWEP:TranslateFOV( fov )
    if not IsValid( self:GetOwner() ) then
        return fov
    end

    local desired = self:GetOwnerDefaultFOV()

    self.ViewModelFOV = self.ViewModelTargetFOV + ( desired - fov ) * 0.6

    return fov
end

function SWEP:HandleViewModel()
    if CLIENT then
        self.SwayScale = SwayScale:GetFloat()
        self.BobScale = BobScale:GetFloat()
    end
end

if CLIENT then
    function SWEP:CalcView( ply, pos, ang, fov )
        if not self:HasCameraControl() then
            return
        end

        return pos, ang - ply:GetViewPunchAngles() * self.Primary.Recoil.Ratio, fov
    end

    function SWEP:AdjustMouseSensitivity()
        if not self:HasCameraControl() then
            return 1
        end

        local desired = self:GetOwnerDefaultFOV()
        local fov = self:GetFOV()

        return fov / desired
    end

    function SWEP:DrawWorldModelTranslucent( flags )
        self:DrawWorldModel( flags )
    end
end
