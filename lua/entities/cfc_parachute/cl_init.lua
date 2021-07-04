include( "shared.lua" )
 
language.Add( "cfc_parachute" )

local tiltMult = 0.2
local furlScaleMult = 0.4
local furlTwistMult = 15

local SCALE_FURLED = Vector( furlScaleMult, furlScaleMult, furlScaleMult )
local ANG_ZERO = Angle( 0, 0, 0 )
local ANG_FURLED_0 = Angle( 0, -furlTwistMult, furlTwistMult )
local ANG_FURLED_1 = Angle( 0, furlTwistMult, furlTwistMult )
local ANG_FURLED_2 = Angle( 0, -furlTwistMult, -furlTwistMult )
local ANG_FURLED_3 = Angle( 0, furlTwistMult, -furlTwistMult )

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

        self:ManipulateBoneAngles( 0, ANG_ZERO )
        self:ManipulateBoneAngles( 1, ANG_ZERO )
        self:ManipulateBoneAngles( 2, ANG_ZERO )
        self:ManipulateBoneAngles( 3, ANG_ZERO )
    else
        self:ManipulateBoneScale( 0, SCALE_FURLED )
        self:ManipulateBoneScale( 1, SCALE_FURLED )
        self:ManipulateBoneScale( 2, SCALE_FURLED )
        self:ManipulateBoneScale( 3, SCALE_FURLED )

        self:ManipulateBoneAngles( 0, ANG_FURLED_0 )
        self:ManipulateBoneAngles( 1, ANG_FURLED_1 )
        self:ManipulateBoneAngles( 2, ANG_FURLED_2 )
        self:ManipulateBoneAngles( 3, ANG_FURLED_3 )
    end
end
