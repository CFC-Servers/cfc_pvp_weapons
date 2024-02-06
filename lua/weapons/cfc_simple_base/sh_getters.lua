AddCSLuaFile()

cfc_simple_weapons.Include( "Convars" )

-- Firing
function SWEP:GetDelay()
    local firemode = self:GetFiremode()

    -- Basic support for burst fire
    if firemode > 0 then
        if self:GetBurstFired() == 0 and self.Primary.BurstEndDelay ~= 0 then
            return self.Primary.BurstEndDelay
        elseif self.Primary.BurstDelay ~= 0 then
            return self.Primary.BurstDelay
        end
    end

    local delay = self.Primary.Delay

    if delay == -1 then
        delay = self:SequenceDuration()
    end

    return delay
end

function SWEP:GetDamage()
    return self.Primary.Damage
end

function SWEP:GetDamageFalloff( distance )
    local distMod = 1000

    return math.max( self.Primary.RangeModifier ^ ( distance / distMod ), MinDamageMult:GetFloat() )
end

function SWEP:GetRange()
    return self.Primary.Range, self.Primary.Accuracy
end

function SWEP:GetSpread( range, accuracy )
    local range2, accuracy2 = self:GetRange()

    range = range or range2
    accuracy = accuracy or accuracy2

    local inches = accuracy / 0.75
    local yards = ( range / 0.75 ) / 36
    local MOA = ( inches * 100 ) / yards

    local spread = math.rad( MOA / 60 )

    return Vector( spread, spread, 0 )
end

-- Recoil
function SWEP:GetRecoilMultiplier()
    return math.tan( self:GetFOV() * ( math.pi / 360 ) ) * self:GetZoom()
end

-- Reloading
function SWEP:GetReloadTime()
    return self.Primary.Reload.Time > 0 and self.Primary.Reload.Time or self:SequenceDuration()
end

-- Zoom
function SWEP:GetZoom()
    return 1 -- Overridden in scoped weapon base
end
