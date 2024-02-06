AddCSLuaFile()

cfc_simple_weapons.Include( "Enums" )

function SWEP:GetAmmoType()
    if self.Primary.Ammo == "" then
        return AMMO_NONE
    elseif self.Primary.ClipSize == -1 then
        return AMMO_NOMAG
    else
        return AMMO_NORMAL
    end
end

function SWEP:ConsumeAmmo()
    if self.AmmoType == AMMO_NONE then return end

    local amountToConsume = math.min( self.Primary.Cost, self:Clip1() )
    if amountToConsume <= 0 then return end

    self:TakePrimaryAmmo( amountToConsume )
end

function SWEP:GetAmmo()
    if self.AmmoType == AMMO_NORMAL then
        return self:Clip1()
    elseif self.AmmoType == AMMO_NOMAG then
        return self:GetOwner():GetAmmoCount( self.Primary.Ammo )
    end

    return 1
end

function SWEP:IsEmpty()
    if self.AmmoType == AMMO_NONE then return false end

    return self:GetAmmo() < self.Primary.Cost
end
