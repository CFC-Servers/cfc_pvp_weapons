include( "shared.lua" )

language.Add( "cfc_parachute" )

local tiltMult = 0.2


function ENT:Initialize()
    self.chuteDir = Vector( 0, 0, 0 )
end

function ENT:SetChuteDirection( chuteDir )
    chuteDir = chuteDir or self.chuteDir
    self.chuteDir = chuteDir

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
