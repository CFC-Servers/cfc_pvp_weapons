include( "shared.lua" )

local tiltMult = 0.2


function ENT:Initialize()
    self.chuteDirRel = Vector( 0, 0, 0 )
end

-- Direction is relative to the player's eyes, and should have x and y each in the range [-1, 1]
function ENT:SetChuteDirection( chuteDirRel )
    chuteDirRel = chuteDirRel or self.chuteDirRel
    self.chuteDirRel = chuteDirRel

    local forward = chuteDirRel.x
    local right = chuteDirRel.y

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
