AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include( "shared.lua" )

CFC_Parachute = CFC_Parachute or {}

local EXPIRATION_DELAY = GetConVar( "cfc_parachute_expiration_delay" )

local COLOR_SHOW = Color( 255, 255, 255, 255 )
local COLOR_HIDE = Color( 255, 255, 255, 0 )
local CHUTE_OFFSET_HEIGHT = 140

local MOVE_KEYS = {
    IN_FORWARD,
    IN_BACK,
    IN_MOVERIGHT,
    IN_MOVELEFT
}
local MOVE_KEY_LOOKUP = {
    [IN_FORWARD] = true,
    [IN_BACK] = true,
    [IN_MOVERIGHT] = true,
    [IN_MOVELEFT] = true,
}
local MOVE_KEY_COUNT = #MOVE_KEYS

local IsValid = IsValid


local function getChutePos( owner )
    local plyHeight = owner:OBBMaxs().z -- mins z is always 0 for players.

    return owner:GetPos() + Vector( 0, 0, CHUTE_OFFSET_HEIGHT * plyHeight / 72 ) -- Scale offset by player height.
end


function ENT:Initialize()
    self._chuteIsOpen = false
    self._chuteMoveForward = 0
    self._chuteMoveBack = 0
    self._chuteMoveRight = 0
    self._chuteMoveLeft = 0
    self._chuteDirRel = Vector( 0, 0, 0 )
    self._chuteDirRel = Vector( 0, 0, 0 )

    self:SetModel( "models/cfc/parachute/chute.mdl" )
    self:PhysicsInit( SOLID_NONE )
    self:SetSolid( SOLID_NONE )
    self:SetNoDraw( true )
    self:DrawShadow( false )
    self:SetColor( COLOR_HIDE )
    self:SetCollisionGroup( COLLISION_GROUP_IN_VEHICLE )
    self:SetRenderMode( RENDERMODE_TRANSCOLOR )
    self:PhysWake()

    timer.Simple( 0.02, function()
        self:_UpdateMoveKeys()

        -- Set owner for clientside updates.
        -- Uses :SetNWEntity() since :SetOwner() will impact CPPI, and net messages are not reliable enough in this case.
        local owner = self._chuteOwner

        if IsValid( owner ) then
            self:SetNWEntity( "cfc_parachute_owner", owner )
        end
    end )

    -- Loosely follow the owner to stay within the same PVS. Client handles more precise positioning.
    local timerNameFollowOwner = "CFC_Parachute_FollowOwner_" .. self:EntIndex()

    timer.Create( timerNameFollowOwner, 2, 0, function()
        if not IsValid( self ) then
            timer.Remove( timerNameFollowOwner )

            return
        end

        local owner = self._chuteOwner
        if not IsValid( owner ) then return end

        self:SetPos( getChutePos( owner ) )
    end )
end

function ENT:Open()
    if not self:CanOpen() then return end

    self._chuteIsOpen = true
    self:SetNoDraw( false )
    self:DrawShadow( true )
    self:_UpdateChuteDirection()

    self:EmitSound( "physics/cardboard/cardboard_box_break3.wav", 85, 100, 1 )
    self:SetColor( COLOR_SHOW )

    timer.Remove( "CFC_Parachute_ExpireChute_" .. self:EntIndex() )
end

function ENT:Close( expireDelay )
    if not self._chuteIsOpen then return end

    self._chuteIsOpen = false
    self:SetNoDraw( true )
    self:DrawShadow( false )

    self:EmitSound( "physics/wood/wood_crate_impact_hard4.wav", 85, 100, 1 )
    self:SetColor( COLOR_HIDE )

    timer.Create( "CFC_Parachute_ExpireChute_" .. self:EntIndex(), expireDelay or EXPIRATION_DELAY:GetFloat(), 1, function()
        if not IsValid( self ) then return end

        self:Remove()
    end )
end

function ENT:OnRemove()
    timer.Remove( "CFC_Parachute_ExpireChute_" .. self:EntIndex() )
    timer.Remove( "CFC_Parachute_FollowOwner_" .. self:EntIndex() )

    local owner = self._chuteOwner
    if not IsValid( owner ) then return end

    owner.cfcParachuteChute = nil
end

function ENT:Think()
    if not self._chuteIsOpen then return end

    local owner = self._chuteOwner

    if not IsValid( owner ) then
        self:Remove()

        return
    end

    self:SetAngles( owner:GetAngles() )
    CFC_Parachute._ApplyChuteForces( owner, self )
    self:NextThink( CurTime() )

    return true
end

function ENT:CanOpen()
    if self._chuteIsOpen then return false end

    local owner = self._chuteOwner
    if not IsValid( owner ) then return false end
    if CFC_Parachute.IsPlayerCloseToGround( owner ) then return false end

    return true
end

function ENT:ApplyChuteDesign()
    local owner = self._chuteOwner
    if not IsValid( owner ) then return end

    if not owner.cfcParachuteDesignID then
        local curDesign = owner:GetInfoNum( "cfc_parachute_design", 1 )

        CFC_Parachute.SetDesignSelection( owner, curDesign )

        return
    end

    local designID = owner.cfcParachuteDesignID
    local materialName =
        CFC_Parachute.DesignMaterialNames[designID] or
        CFC_Parachute.DesignMaterialNames[1]
    local fullMaterial = CFC_Parachute.DesignMaterialPrefix .. materialName

    self:SetSubMaterial( 0, fullMaterial )
end


function ENT:_UpdateChuteDirection()
    local chuteDirRel = Vector( self._chuteMoveForward - self._chuteMoveBack, self._chuteMoveRight - self._chuteMoveLeft, 0 )

    net.Start( "CFC_Parachute_DefineChuteDir" )
    net.WriteEntity( self )
    net.WriteVector( chuteDirRel )
    net.Broadcast()

    self._chuteDirRel = chuteDirRel
end

do
    local IN_BACK = IN_BACK
    local IN_FORWARD = IN_FORWARD
    local IN_MOVELEFT  = IN_MOVELEFT
    local IN_MOVERIGHT = IN_MOVERIGHT

    function ENT:_KeyPress( ply, key, state )
        local selfTable = self:GetTable()

        if ply ~= selfTable._chuteOwner then return end
        if not MOVE_KEY_LOOKUP[key] then return end

        if key == IN_FORWARD then
            selfTable._chuteMoveForward = state and 1 or 0
        elseif key == IN_BACK then
            selfTable._chuteMoveBack = state and 1 or 0
        elseif key == IN_MOVERIGHT then
            selfTable._chuteMoveRight = state and 1 or 0
        elseif key == IN_MOVELEFT then
            selfTable._chuteMoveLeft = state and 1 or 0
        end

        if not selfTable._chuteIsOpen then return end

        self:_UpdateChuteDirection()
    end
end

function ENT:_UpdateMoveKeys()
    local owner = self._chuteOwner
    if not IsValid( owner ) then return end

    for i = 1, MOVE_KEY_COUNT do
        local moveKey = MOVE_KEYS[i]

        self:_KeyPress( owner, moveKey, owner:KeyDown( moveKey ) )
    end
end
