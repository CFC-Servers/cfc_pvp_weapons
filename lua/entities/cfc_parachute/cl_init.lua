include( "shared.lua" )

local TILT_MULT = 0.2
local CHUTE_OFFSET_HEIGHT = 140


local function followPlayer( chute, owner )
    local ownerHeight = owner:OBBMaxs().z -- mins z is always 0 for players.
    local isCrouching = owner:Crouching()
    local ownerScale = isCrouching and ( ownerHeight / 36 ) or ( ownerHeight / 72 ) -- Scale compared to default height.

    -- Update the scale of the parachute if the owner's size has changed.
    if chute._chuteOwnerScale ~= ownerScale then
        chute._chuteOwnerScale = ownerScale

        local scaleMatrix = Matrix()

        scaleMatrix:Scale( Vector( ownerScale, ownerScale, ownerScale ) )
        chute:EnableMatrix( "RenderMultiply", scaleMatrix )
    end

    -- Follow the position and angles of the owner.
    local pos = owner:GetPos() + Vector( 0, 0, CHUTE_OFFSET_HEIGHT * ownerScale )
    local ang = owner:GetAngles()
    ang.p = 0 -- LocalPlayer():GetAngles() includes pitch, which we don't want.

    chute:SetPos( pos )
    chute:SetAngles( ang )
end


-- Direction is relative to the player's eyes, and should have x and y each in the range [-1, 1]
function ENT:SetChuteDirection( chuteDirRel )
    chuteDirRel = chuteDirRel or self._chuteDirRel
    self._chuteDirRel = chuteDirRel

    local forward = chuteDirRel.x
    local right = chuteDirRel.y

    local frontRight = ( forward + right ) / 2
    local frontLeft = ( forward - right ) / 2
    local backRight = ( -forward + right ) / 2
    local backLeft = ( -forward - right ) / 2

    local frontRightScale = 1 - frontRight * TILT_MULT
    local frontLeftScale = 1 - frontLeft * TILT_MULT
    local backRightScale = 1 - backRight * TILT_MULT
    local backLeftScale = 1 - backLeft * TILT_MULT

    self:ManipulateBoneScale( 0, Vector( frontRightScale, frontRightScale, frontRightScale ) )
    self:ManipulateBoneScale( 1, Vector( frontLeftScale, frontLeftScale, frontLeftScale ) )
    self:ManipulateBoneScale( 2, Vector( backRightScale, backRightScale, backRightScale ) )
    self:ManipulateBoneScale( 3, Vector( backLeftScale, backLeftScale, backLeftScale ) )
end

function ENT:Think()
    local owner = self:GetOwner()
    if not IsValid( owner ) then return end

    followPlayer( self, owner )
end
