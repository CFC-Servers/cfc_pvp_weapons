AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include( "shared.lua" )

CFC_Parachute = CFC_Parachute or {}

local DRAG_CUTOFF = 15 -- Don't apply drag if the value is equal to or lower than this (prevents near-infinite gliding)
local UNSTABLE_MIN_GAP = GetConVar( "cfc_parachute_destabilize_min_gap" )
local UNSTABLE_MAX_GAP = GetConVar( "cfc_parachute_destabilize_max_gap" )
local UNSTABLE_MAX_DIR_CHANGE = GetConVar( "cfc_parachute_destabilize_max_direction_change" )
local UNSTABLE_MAX_LURCH = GetConVar( "cfc_parachute_destabilize_max_lurch" )
local UNSTABLE_LURCH_CHANCE = GetConVar( "cfc_parachute_destabilize_lurch_chance" )

local COLOR_SHOW = Color( 255, 255, 255, 255 )
local COLOR_HIDE = Color( 255, 255, 255, 0 )

local MOVE_KEYS = {
    IN_FORWARD,
    IN_BACK,
    IN_MOVERIGHT,
    IN_MOVELEFT
}
local MOVE_KEY_COUNT = #MOVE_KEYS

function SWEP:Initialize()
    self.chuteCanUnfurl = true
    self.chuteMoveForward = 0
    self.chuteMoveBack = 0
    self.chuteMoveRight = 0
    self.chuteMoveLeft = 0
    self.chuteLurch = 0
    self.chuteIsUnstable = false
    self.chuteDir = Vector( 0, 0, 0 )

    self:SetRenderMode( RENDERMODE_TRANSCOLOR )

    timer.Simple( 0.1, function()
        if not IsValid( self ) then return end

        self:SetHoldType( "passive" )
    end )
end

function SWEP:OnRemove()
    timer.Remove( "CFC_Parachute_UnstableDirectionChange_" .. self:EntIndex() )

    local owner = self:GetOwner()

    if not IsValid( owner ) then return end

    net.Start( "CFC_Parachute_GrabChuteStraps" )
    net.WriteEntity( owner )
    net.WriteBool( false )
    net.Broadcast()
end

function SWEP:SpawnChute()
    local chute = self.chuteEnt

    if IsValid( chute ) then return chute end

    local owner = self:GetOwner()
    local chute = ents.Create( "cfc_parachute" )

    chute:SetPos( self:GetPos() + Vector( 0, 0, 146.6565 - 43.5 ) )
    chute:SetAngles( self:GetAngles() )
    chute:SetParent( self )

    chute.chuteIsOpen = false
    chute.chuteIsUnfurled = false
    chute.chutePack = self

    if IsValid( owner ) then
        chute.chuteOwner = owner
    else
        timer.Simple( 0.01, function()
            local owner = self:GetOwner()
            owner = IsValid( owner ) and owner

            chute.chuteOwner = owner

            self:SetColor( COLOR_SHOW )
            chute:SetColor( COLOR_HIDE )
        end )
    end

    chute:Spawn()

    self.chuteEnt = chute
    self.chuteIsOpen = false
    self.chuteIsUnfurled = false
    self.chuteDir = Vector( 0, 0, 0 )

    self.chuteDrag  = GetConVar( "cfc_parachute_drag" ):GetFloat()
    self.chuteDragUnfurled  = GetConVar( "cfc_parachute_drag_unfurled" ):GetFloat()
    self.chuteSpeed  = GetConVar( "cfc_parachute_speed" ):GetFloat()
    self.chuteSpeedUnfurled  = GetConVar( "cfc_parachute_speed_unfurled" ):GetFloat()
    self.chuteSpeedMax  = GetConVar( "cfc_parachute_speed_max" ):GetFloat()

    hook.Run( "CFC_Parachute_ChuteCreated", chute )

    timer.Simple( 0.02, function()
        local owner = self:GetOwner() or chute.chuteOwner

        if not IsValid( owner ) or not owner:IsPlayer() then return end

        local shouldBeUnfurled = owner:GetInfoNum( "cfc_parachute_unfurl_invert", 0 ) ~= 0
        chute.chuteIsUnfurled = shouldBeUnfurled
        self.chuteIsUnfurled = shouldBeUnfurled

        net.Start( "CFC_Parachute_DefineChuteUnfurlStatus" )
        net.WriteEntity( chute )
        net.WriteBool( shouldBeUnfurled )
        net.Broadcast()

        self:UpdateMoveKeys()
    end )

    return chute
end

function SWEP:ApplyChuteForces()
    if not self.chuteIsOpen then return end

    local owner = self:GetOwner() or chute.chuteOwner

    if not IsValid( owner ) then return end

    local vel = owner:GetVelocity()
    local drag = math.max( -vel.z, 0 )

    if drag < DRAG_CUTOFF then return end

    local thrustDir

    local unfurled = self.chuteIsUnfurled
    local thrust = drag * ( unfurled and self.chuteSpeedUnfurled or self.chuteSpeed )

    if self.chuteIsUnstable then
        thrustDir = self.chuteDir
    else
        local eyeAngles = owner:EyeAngles()
        local eyeForward = eyeAngles:Forward()
        local eyeRight = eyeAngles:Right()
        local chuteDir = self.chuteDir
        
        thrustDir = ( eyeForward * chuteDir.x + eyeRight * chuteDir.y ) * Vector( 1, 1, 0 )
    end

    local speedMax = self.chuteSpeedMax
    local curSpeed = ( vel.x ^ 2 + vel.y ^ 2 ) ^ 0.5
    local lurch = self.chuteLurch

    drag = drag * ( unfurled and self.chuteDragUnfurled or self.chuteDrag )
    thrust = math.min( thrust, self.chuteSpeedMax - curSpeed - thrust )

    if curSpeed > speedMax * 1.5 then
        owner:SetVelocity( Vector( 0, 0, drag + lurch ) - vel * Vector( 1, 1, 0 ) )
    else
        owner:SetVelocity( Vector( 0, 0, drag + lurch ) + thrustDir * thrust )
    end

    if lurch ~= 0 then
        self.chuteLurch = 0
    end
end

function SWEP:SetChuteDirection()
    local chuteDir = Vector( self.chuteMoveForward - self.chuteMoveBack, self.chuteMoveRight - self.chuteMoveLeft, 0 )

    -- Client does not receive the normalized version to make its math simpler
    net.Start( "CFC_Parachute_DefineChuteDir" )
    net.WriteEntity( self:SpawnChute() )
    net.WriteVector( chuteDir )
    net.Broadcast()

    chuteDir:Normalize()

    self.chuteDir = chuteDir
end

function SWEP:ChangeOwner( ply )
    local chute = self:SpawnChute()

    ply = IsValid( ply ) and ply

    self.chuteOwner = ply
    self:SetOwner( ply )

    chute.chuteOwner = ply
    chute.chuteIsOpen = false
    chute.chuteIsUnfurled = false
    chute:SetOwner( ply )

    timer.Simple( 0.01, function()
        net.Start( "CFC_Parachute_DefineChuteUnfurlStatus" )
        net.WriteEntity( chute )
        net.WriteBool( false )
        net.Broadcast()
    end )

    self:SetColor( COLOR_SHOW )
    chute:SetColor( COLOR_HIDE )
end

function SWEP:ChangeOpenStatus( state, ply )
    local owner = ply or self:GetOwner() or self.chuteOwner
    local prevState = self.chuteIsOpen

    if not IsValid( owner ) then return end

    if state == nil then
        state = not prevState
    elseif state == prevState then return end

    if owner:IsOnGround() and state then return end

    local chute = self:SpawnChute()

    self.chuteIsOpen = state

    if state then
        self:SetColor( COLOR_HIDE )
        self:SetChuteDirection()

        chute:Open()

        owner:AnimRestartGesture( GESTURE_SLOT_CUSTOM, ACT_GMOD_NOCLIP_LAYER, false )
        owner:AnimRestartGesture( GESTURE_SLOT_JUMP, ACT_HL2MP_IDLE_PASSIVE, false )
    else
        self:SetColor( COLOR_SHOW )

        chute:Close()

        owner:AnimResetGestureSlot( GESTURE_SLOT_CUSTOM )
        owner:AnimResetGestureSlot( GESTURE_SLOT_JUMP )
    end

    net.Start( "CFC_Parachute_GrabChuteStraps" )
    net.WriteEntity( owner )
    net.WriteBool( state )
    net.Broadcast()
end

function SWEP:ApplyUnstableLurch()
    local owner = self:GetOwner()

    if not IsValid( owner ) or owner.cfcParachuteInstabilityImmune then return end
    
    local maxLurch = UNSTABLE_MAX_LURCH:GetFloat()
    local lurchForce = -math.Rand( 0, maxLurch )

    self.chuteLurch = self.chuteLurch + lurchForce
end

function SWEP:ApplyUnstableDirectionChange()
    local owner = self:GetOwner() or self.chuteOwner

    if not IsValid( owner ) or owner.cfcParachuteInstabilityImmune then return end

    local maxChange = UNSTABLE_MAX_DIR_CHANGE:GetFloat()
    local chuteDir = self.chuteDir

    chuteDir:Rotate( Angle( 0, math.Rand( maxChange, maxChange ), 0 ) )

    net.Start( "CFC_Parachute_DefineChuteDir" )
    net.WriteEntity( self:SpawnChute() )
    net.WriteVector( chuteDir )
    net.Broadcast()
end

function SWEP:CreateUnstableDirectionTimer()
    local timerName = "CFC_Parachute_UnstableDirectionChange_" .. self:EntIndex()
    local delay = math.Rand( UNSTABLE_MIN_GAP:GetFloat(), UNSTABLE_MAX_GAP:GetFloat() )

    timer.Create( timerName, delay, 1, function()
        self:ApplyUnstableDirectionChange()
        self:CreateUnstableDirectionTimer()

        if math.Rand( 0, 1 ) <= UNSTABLE_LURCH_CHANCE:GetFloat() then
            self:ApplyUnstableLurch()
        end
    end )
end

function SWEP:ChangeInstabilityStatus( state )
    local prevState = self.chuteIsUnstable

    if state == nil then
        state = not prevState
    elseif state == prevState then return end

    self.chuteIsUnstable = state

    if state then
        local owner = self:GetOwner()

        if not IsValid( owner ) then return end

        local eyeAngles = owner:EyeAngles()
        local eyeForward = eyeAngles:Forward()
        local eyeRight = eyeAngles:Right()
        local chuteDir = self.chuteDir

        if not chuteDir or chuteDir == Vector( 0, 0, 0 ) then
            chuteDir = Angle( 0, math.Rand( 0, 360 ), 0 ):Forward()
        end

        self.chuteDir = ( eyeForward * chuteDir.x + eyeRight * chuteDir.y ) * Vector( 1, 1, 0 )

        self:CreateUnstableDirectionTimer()
    else
        self:SetChuteDirection()
        self.chuteLurch = 0
        
        timer.Remove( "CFC_Parachute_UnstableDirectionChange_" .. self:EntIndex() )
    end
end

function SWEP:ApplyChuteDesign()
    local owner = self:GetOwner()

    if not IsValid( owner ) then return end

    local chute = self:SpawnChute()
    local designID = owner.cfcParachuteDesignID or 1
    local designMaterials = CFC_Parachute.DesignMaterials

    if not designMaterials then
        timer.Simple( 1, function()

            self:ApplyChuteDesign()
        end )

        return
    end

    local skinID = ( designID == 1034 and chute:SkinCount() or designID ) - 1

    chute:SetSkin( skinID )
end

function SWEP:PrimaryAttack()
    self:SetNextPrimaryFire( CurTime() + self.Primary.Delay )
    
    if self:CanPrimaryAttack() == false then return end

    self:ChangeOpenStatus()
end

function SWEP:SecondaryAttack()
    
    self:SetNextSecondaryFire( CurTime() + self.Primary.Delay )
end

function SWEP:Deploy()
    local owner = self:GetOwner()

    self:ChangeInstabilityStatus( false )

    if not IsValid( owner ) then return end
    
    local state = self.chuteIsOpen

    if not state then return end

    net.Start( "CFC_Parachute_GrabChuteStraps" )
    net.WriteEntity( owner )
    net.WriteBool( true )
    net.Broadcast()
end

function SWEP:Holster()
    local owner = self:GetOwner()

    self:ChangeInstabilityStatus( true )

    if not IsValid( owner ) then return true end
    
    local state = self.chuteIsOpen

    if not state then return true end

    net.Start( "CFC_Parachute_GrabChuteStraps" )
    net.WriteEntity( owner )
    net.WriteBool( false )
    net.Broadcast()

    return true
end

function SWEP:Equip( ply )
    if not IsValid( ply ) or not ply:IsPlayer() then return end

    timer.Simple( 0.1, function()
        if not ply.cfcParachuteDesignID then
            -- Requests the client to send their design selection since :GetInfoNum() is not behaving correctly even with FCVAR_USERINFO
            -- Could be due to FCVAR_NEVER_AS_STRING if :GetInfoNum() expects a string that it then converts, without caring about the original type

            net.Start( "CFC_Parachute_SelectDesign" )
            net.Send( ply )
        else
            self:ApplyChuteDesign()
        end

        if ply.cfcParachuteKnowsDesigns then return end

        local designMaterials = CFC_Parachute.DesignMaterials

        if not designMaterials then
            local chute = self.chuteEnt

            if IsValid( chute ) then
                hook.Run( "CFC_Parachute_ChuteCreated", chute )

                designMaterials = CFC_Parachute.DesignMaterials
            else
                self:SpawnChute()
            end
        end

        net.Start( "CFC_Parachute_DefineDesigns" )
        net.WriteTable( designMaterials )
        net.WriteTable( CFC_Parachute.DesignMaterialNames )
        net.WriteInt( CFC_Parachute.DesignMaterialCount, 17 )
        net.Send( ply )
        
        ply.cfcParachuteKnowsDesigns = true
    end )
end

function SWEP:KeyPress( ply, key, state )
    if ply ~= self:GetOwner() or self.chuteIsUnstable then return end
    
    if key == IN_JUMP then
        if not self.chuteCanUnfurl then return end

        local isToggle = ply:GetInfoNum( "cfc_parachute_unfurl_toggle", 0 ) ~= 0

        if isToggle then
            if not state or not self.chuteIsOpen then return end
            state = not self.chuteIsUnfurled
        elseif ply:GetInfoNum( "cfc_parachute_unfurl_invert", 0 ) ~= 0 then
            state = not state
        end

        self.chuteCanUnfurl = false
        self.chuteIsUnfurled = state

        if self.chuteIsOpen then
            if state then
                self:SpawnChute():Unfurl()
            else
                self:SpawnChute():Furl()
            end
        else
            local chute = self:SpawnChute()
            
            chute.chuteIsUnfurled = state

            net.Start( "CFC_Parachute_DefineChuteUnfurlStatus" )
            net.WriteEntity( chute )
            net.WriteBool( state )
            net.Broadcast()
        end

        timer.Simple( self.Primary.Delay, function()
            self.chuteCanUnfurl = true
        end )
    elseif key == IN_FORWARD then
        self.chuteMoveForward = state and 1 or 0

        if not self.chuteIsOpen then return end

        self:SetChuteDirection()
    elseif key == IN_BACK then
        self.chuteMoveBack = state and 1 or 0

        if not self.chuteIsOpen then return end
        
        self:SetChuteDirection()
    elseif key == IN_MOVERIGHT then
        self.chuteMoveRight = state and 1 or 0

        if not self.chuteIsOpen then return end

        self:SetChuteDirection()
    elseif key == IN_MOVELEFT then
        self.chuteMoveLeft = state and 1 or 0

        if not self.chuteIsOpen then return end

        self:SetChuteDirection()
    end
end

function SWEP:UpdateMoveKeys()
    local owner = self:GetOwner()
    owner = IsValid( owner ) and owner or self.chuteOwner

    if not IsValid( owner ) or not owner:IsPlayer() then return end

    if owner:GetInfoNum( "cfc_parachute_unfurl_toggle", 0 ) == 0 then
        self:KeyPress( owner, IN_JUMP, owner:KeyDown( IN_JUMP ) )
    end

    for i = 1, MOVE_KEY_COUNT do
        local moveKey = MOVE_KEYS[i]

        self:KeyPress( owner, moveKey, owner:KeyDown( moveKey ) )
    end
end
