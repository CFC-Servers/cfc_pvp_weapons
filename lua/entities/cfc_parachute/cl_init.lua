include( "shared.lua" )
 
language.Add( "cfc_parachute" )

local tiltMult = 0.2
local furlScaleMult = 0.4
local furlTwistMult = 15

function ENT:Initialize()
    self.chuteDir = Vector( 0, 0, 0 )
    self.chuteIsUnfurled = false
end

function ENT:SetChuteDirection( chuteDir )
    chuteDir = chuteDir or self.chuteDir
    self.chuteDir = chuteDir

    if not self.chuteIsUnfurled then return end

    local forward = chuteDir.x
    local right = chuteDir.y

    local frontRight = ( forward + right ) / 2
    local frontLeft = ( forward - right ) / 2
    local backRight = ( -forward + right ) / 2
    local backLeft = ( -forward - right ) / 2

    local frontRightScale = 1 - frontRight * tiltMult
    local frontLeftScale = 1 - frontLeft * tiltMult
    local backRightScale = 1 - backRight * tiltMult
    local backLeftScale = 1 - backLeft * tiltMult

    self:ManipulateBoneScale( 0, Vector( frontRightScale, frontRightScale, frontRightScale ) )
    self:ManipulateBoneScale( 1, Vector( frontLeftScale, frontLeftScale, frontLeftScale ) )
    self:ManipulateBoneScale( 2, Vector( backRightScale, backRightScale, backRightScale ) )
    self:ManipulateBoneScale( 3, Vector( backLeftScale, backLeftScale, backLeftScale ) )
end

function ENT:SetUnfurlStatus( state )
    self.chuteIsUnfurled = state

    if state then
        self:SetChuteDirection()

        local resetAng = Angle( 0, 0, 0 )

        self:ManipulateBoneAngles( 0, resetAng )
        self:ManipulateBoneAngles( 1, resetAng )
        self:ManipulateBoneAngles( 2, resetAng )
        self:ManipulateBoneAngles( 3, resetAng )
    else
        local furlSize = Vector( furlScaleMult, furlScaleMult, furlScaleMult )

        self:ManipulateBoneScale( 0, furlSize )
        self:ManipulateBoneScale( 1, furlSize )
        self:ManipulateBoneScale( 2, furlSize )
        self:ManipulateBoneScale( 3, furlSize )

        self:ManipulateBoneAngles( 0, Angle( 0, -furlTwistMult, furlTwistMult ) )
        self:ManipulateBoneAngles( 1, Angle( 0, furlTwistMult, furlTwistMult ) )
        self:ManipulateBoneAngles( 2, Angle( 0, -furlTwistMult, -furlTwistMult ) )
        self:ManipulateBoneAngles( 3, Angle( 0, furlTwistMult, -furlTwistMult ) )
    end
end
