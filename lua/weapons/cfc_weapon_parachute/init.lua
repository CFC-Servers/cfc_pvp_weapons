AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include( "shared.lua" )

CFC_Parachute = CFC_Parachute or {}

local UNSTABLE_MIN_GAP = GetConVar( "cfc_parachute_destabilize_min_gap" )
local UNSTABLE_MAX_GAP = GetConVar( "cfc_parachute_destabilize_max_gap" )
local UNSTABLE_MAX_DIR_CHANGE = GetConVar( "cfc_parachute_destabilize_max_direction_change" )
local UNSTABLE_MAX_LURCH = GetConVar( "cfc_parachute_destabilize_max_lurch" )
local UNSTABLE_LURCH_CHANCE = GetConVar( "cfc_parachute_destabilize_lurch_chance" )

local COLOR_SHOW = Color( 255, 255, 255, 255 )
local COLOR_HIDE = Color( 255, 255, 255, 0 )
local TRACE_HULL_SCALE_DOWN = Vector( 0.95, 0.95, 0.01 )
local GROUND_CLASS_IGNORE = { -- Classes that should be ignored for the CloseIfOnGround() check
    -- HL2
    crossbow_bolt = true,
    prop_combine_ball = true,
    npc_satchel = true,
    npc_grenade_frag = true,
    -- CW2
    ent_ins2rpgrocket = true,
    cw_grenade_thrown = true,
    cw_flash_thrown = true,
    cw_smoke_thrown = true,
    cw_40mm_explosive = true,
    -- LFS
    lunasflightschool_missile = true,
    -- M9K
    m9k_proxy = true,
    m9k_thrown_nitrox = true,
    m9k_thrown_m61 = true,
    m9k_thrown_sticky_grenade = true,
    m9k_thrown_harpoon = true,
    m9k_nervegasnade = true,
    m9k_ammo_rpg_heat = true,
    m9k_thrown_knife = true,
    m9k_ammo_matador_90mm = true,
    m9k_launched_m79 = true,
    m9k_launched_flare = true,
    -- Misc
    env_flare = true,
}

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
local MOVETYPE_NOCLIP = MOVETYPE_NOCLIP

local IsValid = IsValid


function SWEP:Initialize()
    self.chuteMoveForward = 0
    self.chuteMoveBack = 0
    self.chuteMoveRight = 0
    self.chuteMoveLeft = 0
    self.chuteLurch = 0
    self.chuteIsUnstable = false
    self.chuteDirRel = Vector( 0, 0, 0 )

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
    local chuteEnt = self.chuteEnt
    if IsValid( chuteEnt ) then return chuteEnt end

    local chuteOwner = self:GetOwner()
    local chute = ents.Create( "cfc_parachute" )

    chute:SetPos( self:GetPos() + Vector( 0, 0, 146.6565 - 43.5 ) )
    chute:SetAngles( self:GetAngles() )
    chute:SetParent( self )

    chute.chuteIsOpen = false
    chute.chutePack = self

    if IsValid( chuteOwner ) then
        chute.chuteOwner = chuteOwner
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
    self.chuteDirRel = Vector( 0, 0, 0 )

    hook.Run( "CFC_Parachute_ChuteCreated", chute )

    timer.Simple( 0.02, function()
        local owner = self:GetOwner() or chute.chuteOwner
        if not IsValid( owner ) then return end
        if not owner:IsPlayer() then return end

        self:_UpdateMoveKeys()
    end )

    return chute
end

function SWEP:_UpdateChuteDirection()
    local chuteDirRel = Vector( self.chuteMoveForward - self.chuteMoveBack, self.chuteMoveRight - self.chuteMoveLeft, 0 )
    local animationDir = self.chuteIsUnstable and Vector() or chuteDirRel

    net.Start( "CFC_Parachute_DefineChuteDir" )
    net.WriteEntity( self:SpawnChute() )
    net.WriteVector( animationDir )
    net.Broadcast()

    self.chuteDirRel = chuteDirRel
end

function SWEP:ChangeOwner( ply )
    ply = IsValid( ply ) and ply

    local chute = self:SpawnChute()

    self.chuteOwner = ply
    self:SetOwner( ply )

    chute.chuteOwner = ply
    chute.chuteIsOpen = false
    chute:SetOwner( ply )

    self:SetColor( COLOR_SHOW )
    chute:SetColor( COLOR_HIDE )

    CFC_Parachute.SetSpaceEquipReadySilent( ply, true )
end

function SWEP:CanOpen()
    local owner = self:GetOwner() or self.chuteOwner
    if not IsValid( owner ) then return false end
    if owner:IsOnGround() then return false end
    if owner:WaterLevel() > 0 then return false end

    local startPos = owner:GetPos()
    local endPos = startPos + Vector( 0, 0, -70 )
    local tr = util.TraceLine( {
        start = startPos,
        endpos = endPos,
    } )

    if tr.Hit then return false end

    return true
end

function SWEP:ChangeOpenStatus( state, ply )
    local owner = ply or self:GetOwner() or self.chuteOwner
    if not IsValid( owner ) then return end

    local prevState = self.chuteIsOpen

    if state == nil then
        state = not prevState
    elseif state == prevState then return end

    if state and not self:CanOpen() then return end

    local chute = self:SpawnChute()

    self.chuteIsOpen = state

    if state then
        self:SetColor( COLOR_HIDE )
        self:_UpdateChuteDirection()

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

function SWEP:CloseIfOnGround()
    if not self.chuteIsOpen then return end

    local owner = self.chuteOwner
    if not IsValid( owner ) then return end

    -- Extends the trace length to ensure the player doesn't clip into the floor, even at (reasonably) high velocities
    local extendByVelMult = 0.5
    local extendByVelMax = 30
    local extendFlat = 4

    local velZ = owner:GetVelocity()[3]
    local traceExtend = extendFlat

    if velZ < 0 then
        traceExtend = traceExtend + math.min( -velZ * extendByVelMult, extendByVelMax )
    end

    local tr = util.TraceHull( {
        start = owner:GetPos() + Vector( 0, 0, owner:OBBMaxs()[3] * 0.9 ),
        endpos = owner:GetPos() + Vector( 0, 0, -traceExtend ),
        mins = owner:OBBMins() * TRACE_HULL_SCALE_DOWN,
        maxs = owner:OBBMaxs() * TRACE_HULL_SCALE_DOWN,
        filter = owner,
    } )

    if tr.Hit then
        local ent = tr.Entity

        -- Don't close from projectiles like crossbow bolts or RPGs. Annoyingly, all these objects have different collision groups, etc, and aren't standardized at all.
        if IsValid( ent ) and GROUND_CLASS_IGNORE[ent:GetClass()] then return end

        self:ChangeOpenStatus( false )
    end
end

function SWEP:CloseIfInWater()
    if not self.chuteIsOpen then return end
    if self:WaterLevel() == 0 then return end
    -- Water level updates seem to get suppressed on the player while using the Move hook, but we can conveniently check the swep instead

    self:ChangeOpenStatus( false )
end

function SWEP:ApplyUnstableLurch()
    local owner = self:GetOwner()
    if not IsValid( owner ) then return end
    if owner.cfcParachuteInstabilityImmune then return end

    local maxLurch = UNSTABLE_MAX_LURCH:GetFloat()
    local lurchForce = -math.Rand( 0, maxLurch )

    self.chuteLurch = self.chuteLurch + lurchForce
end

function SWEP:ApplyUnstableDirectionChange()
    local owner = self:GetOwner() or self.chuteOwner
    if not IsValid( owner ) then return end
    if owner.cfcParachuteInstabilityImmune then return end

    local maxChange = UNSTABLE_MAX_DIR_CHANGE:GetFloat()
    local chuteDirUnstable = self.chuteDirUnstable

    chuteDirUnstable:Rotate( Angle( 0, math.Rand( maxChange, maxChange ), 0 ) )
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
        local chuteDirRel = self.chuteDirRel

        if not chuteDirRel or chuteDirRel == Vector( 0, 0, 0 ) then
            chuteDirRel = Angle( 0, math.Rand( 0, 360 ), 0 ):Forward()
        end

        local chuteDirUnstable = ( eyeForward * chuteDirRel.x + eyeRight * chuteDirRel.y ) * Vector( 1, 1, 0 )
        chuteDirUnstable:Normalize()

        self.chuteDirUnstable = chuteDirUnstable
        self:CreateUnstableDirectionTimer()
    else
        self.chuteLurch = 0

        timer.Remove( "CFC_Parachute_UnstableDirectionChange_" .. self:EntIndex() )
    end

    self:_UpdateChuteDirection()
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
    self:ChangeInstabilityStatus( false )

    local owner = self:GetOwner()
    if not IsValid( owner ) then return end

    local state = self.chuteIsOpen
    if not state then return end

    net.Start( "CFC_Parachute_GrabChuteStraps" )
    net.WriteEntity( owner )
    net.WriteBool( true )
    net.Broadcast()
end

function SWEP:Holster()
    self:ChangeInstabilityStatus( true )

    local owner = self:GetOwner()
    if not IsValid( owner ) then return true end

    if owner:GetMoveType() == MOVETYPE_NOCLIP then
        self:ChangeOpenStatus( false, owner )
    end

    local state = self.chuteIsOpen
    if not state then return true end

    net.Start( "CFC_Parachute_GrabChuteStraps" )
    net.WriteEntity( owner )
    net.WriteBool( false )
    net.Broadcast()

    return true
end

function SWEP:Equip( ply )
    if not IsValid( ply ) then return end
    if not ply:IsPlayer() then return end

    timer.Simple( 0.1, function()
        if not IsValid( ply ) then return end

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


function SWEP:_KeyPress( ply, key, state )
    if ply ~= self:GetOwner() or self.chuteIsUnstable then return end

    if MOVE_KEY_LOOKUP[key] then
        if key == IN_FORWARD then
            self.chuteMoveForward = state and 1 or 0
        elseif key == IN_BACK then
            self.chuteMoveBack = state and 1 or 0
        elseif key == IN_MOVERIGHT then
            self.chuteMoveRight = state and 1 or 0
        elseif key == IN_MOVELEFT then
            self.chuteMoveLeft = state and 1 or 0
        end

        if not self.chuteIsOpen then return end

        self:_UpdateChuteDirection()
    end
end

function SWEP:_UpdateMoveKeys()
    local owner = self:GetOwner()
    owner = IsValid( owner ) and owner or self.chuteOwner

    if not IsValid( owner ) then return end
    if not owner:IsPlayer() then return end

    for i = 1, MOVE_KEY_COUNT do
        local moveKey = MOVE_KEYS[i]

        self:_KeyPress( owner, moveKey, owner:KeyDown( moveKey ) )
    end
end

function SWEP:_ApplyChuteForces()
    if not self.chuteIsOpen then return end

    local owner = self:GetOwner() or self.chuteOwner
    if not IsValid( owner ) then return end

    CFC_Parachute._ApplyChuteForces( owner, self )
end
