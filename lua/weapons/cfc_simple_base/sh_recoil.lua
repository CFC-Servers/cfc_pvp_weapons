AddCSLuaFile()

cfc_simple_weapons.Include( "Convars" )

function SWEP:ApplyRecoil( recoil, mult )
    local ply = self:GetOwner()

    if not ply:IsPlayer() then
        return
    end

    recoil = recoil or self.Primary.Recoil

    local seed = ply:GetCurrentCommand():CommandNumber()
    mult = self:GetRecoilMultiplier() * ( mult or 1 )

    local pitch = -util.SharedRandom( self:EntIndex() .. seed .. "1", recoil.MinAng.p, recoil.MaxAng.p ) * mult
    local yaw = util.SharedRandom( self:EntIndex() .. seed .. "2", recoil.MinAng.y, recoil.MaxAng.y ) * mult

    if game.SinglePlayer() or ( CLIENT and IsFirstTimePredicted() ) then
        ply:SetEyeAngles( ply:EyeAngles() + Angle( pitch, yaw, 0 ) * recoil.Punch )
    end

    ply:ViewPunch( Angle( pitch, yaw, 0 ) )
end

function SWEP:ApplyStaticRecoil( ang, recoil, mult, notInPredictedHook )
    local ply = self:GetOwner()

    if not ply:IsPlayer() then
        return
    end

    recoil = recoil or self.Primary.Recoil
    mult = self:GetRecoilMultiplier() * ( mult or 1 )

    local pitch = -ang.p * mult
    local yaw = ang.y * mult

    if game.SinglePlayer() or ( CLIENT and ( notInPredictedHook or IsFirstTimePredicted() ) ) then
        ply:SetEyeAngles( ply:EyeAngles() + Angle( pitch, yaw, 0 ) * recoil.Punch )
    end

    ply:ViewPunch( Angle( pitch, yaw, 0 ) )
end
