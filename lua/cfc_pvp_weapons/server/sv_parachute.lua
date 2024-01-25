CFC_Parachute = CFC_Parachute or {}

-- Convars
local SPACE_EQUIP_SV
local SPACE_EQUIP_DOUBLE_SV
local QUICK_CLOSE_ADVANCED_SV

-- Convar value localizations
local cvFallZVel
local cvFallLerp
local cvHorizontalSpeed
local cvHorizontalSpeedLimit
local cvSprintBoost
local cvHandling
local cvSpaceEquipZVelThreshold

-- Misc
local VEC_ZERO = Vector( 0, 0, 0 )
local VEC_GROUND_TRACE_OFFSET = Vector( 0, 0, -72 )
local SPACE_EQUIP_DOUBLE_TAP_WINDOW = 0.35
local QUICK_CLOSE_WINDOW = 0.35

local IsValid = IsValid
local CurTime = CurTime

local designRequestNextTimes = {}


--[[
    - Returns moveDir, increasing its magnitude if it opposes vel.
    - Ultimately makes it faster to brake and change directions.
    - moveDir should be given as a unit vector.
--]]
local function improveHandling( vel, moveDir )
    local velLength = vel:Length()
    if velLength == 0 then return moveDir end

    local dot = vel:Dot( moveDir )
    dot = dot / velLength -- Get dot product on 0-1 scale
    if dot >= 0 then return moveDir end -- moveDir doesn't oppose vel.

    local mult = math.max( -dot * cvHandling, 1 )

    return moveDir * mult
end

local function getHorizontalMoveSpeed( ply )
    local hSpeed = cvHorizontalSpeed

    if ply:KeyDown( IN_SPEED ) then
        return hSpeed * cvSprintBoost
    end

    return hSpeed
end

-- Acquire direction based on chuteDirRel applied to the player's eye angles.
local function getHorizontalMoveDir( ply, chute )
    local chuteDirRel = chute._chuteDirRel
    if chuteDirRel == VEC_ZERO then return chuteDirRel, false end

    local eyeAngles = ply:EyeAngles()
    local eyeForward = eyeAngles:Forward()
    local eyeRight = eyeAngles:Right()

    local moveDir = ( eyeForward * chuteDirRel.x + eyeRight * chuteDirRel.y ) * Vector( 1, 1, 0 )
    moveDir:Normalize()

    return moveDir, true
end

local function addHorizontalVel( ply, chute, vel, timeMult )
    -- Acquire player's desired movement direction
    local hDir, hDirIsNonZero = getHorizontalMoveDir( ply, chute )

    -- Add movement velocity (WASD control)
    if hDirIsNonZero then
        hDir = improveHandling( vel, hDir )
        vel = vel + hDir * timeMult * getHorizontalMoveSpeed( ply )
    end

    -- Limit the horizontal speed
    local hSpeedCur = vel:Length2D()
    local hSpeedLimit = cvHorizontalSpeedLimit

    if hSpeedCur > hSpeedLimit then
        local mult = hSpeedLimit / hSpeedCur

        vel[1] = vel[1] * mult
        vel[2] = vel[2] * mult
    end

    return vel
end

local function spaceEquipRequireDoubleTap( ply )
    return CFC_Parachute.GetConVarPreference( ply, "cfc_parachute_space_equip_double", SPACE_EQUIP_DOUBLE_SV )
end

local function quickCloseAdvancedEnabled( ply )
    return CFC_Parachute.GetConVarPreference( ply, "cfc_parachute_quick_close_advanced", QUICK_CLOSE_ADVANCED_SV )
end


--[[
    - Get a player's true/false preference for a convar, or the server default if they haven't set it.
    - Requires a userinfo convar and a server convar sharing the same name with "_sv" at the end.
    - svConvarObject is optional, and will be retrieved if not provided.
--]]
function CFC_Parachute.GetConVarPreference( ply, convarName, svConvarObject )
    local plyVal = ply:GetInfoNum( convarName, 2 )
    if plyVal == 1 then return true end
    if plyVal == 0 then return false end

    -- Use server default.
    svConvarObject = svConvarObject or GetConVar( convarName .. "_sv" )
    local serverDefault = svConvarObject:GetString()

    return serverDefault ~= "0"
end

function CFC_Parachute.SetDesignSelection( ply, newDesign )
    if not IsValid( ply ) then return end

    local validatedDesign = newDesign

    -- Validate design ID, falling back to the previous one if necessary.
    if not CFC_Parachute.DesignMaterialNames[newDesign] then
        validatedDesign = ply.cfcParachuteDesignID or 1
    end

    if newDesign ~= validatedDesign then
        ply:ConCommand( "cfc_parachute_design " .. validatedDesign )

        return
    end

    ply.cfcParachuteDesignID = validatedDesign

    local chute = ply.cfcParachuteChute

    if IsValid( chute ) then
        chute:ApplyChuteDesign()
    end
end

function CFC_Parachute.OpenParachute( ply )
    if not IsValid( ply ) then return end

    local chute = ply.cfcParachuteChute

    -- Parachute is valid, open it.
    if IsValid( chute ) then
        chute:Open()

        return
    end

    -- Spawn a parachute.
    chute = ents.Create( "cfc_parachute" )
    ply.cfcParachuteChute = chute

    chute:SetPos( ply:GetPos() )
    chute:SetOwner( ply )
    chute:Spawn()
    chute:ApplyChuteDesign()

    -- Open the parachute.
    timer.Simple( 0.1, function()
        if not IsValid( ply ) then return end
        if not IsValid( chute ) then return end

        if ply:InVehicle() then
            chute:Close( 0.5 )
        else
            chute:Open()
        end
    end )
end

--[[
    - Whether or not the player is able and willing to use space-equip.
    - You can return false in the CFC_Parachute_CanSpaceEquip hook to block this.
        - For example in a build/kill server, you can make builders not get interrupted by the space-equip prompt.
--]]
function CFC_Parachute.CanSpaceEquip( ply )
    if not IsValid( ply ) then return false end
    if hook.Run( "CFC_Parachute_CanSpaceEquip", ply ) == false then return false end

    return true
end

function CFC_Parachute.IsPlayerCloseToGround( ply )
    if ply:IsOnGround() then return true end
    if ply:WaterLevel() > 0 then return true end

    local startPos = ply:GetPos()
    local endPos = startPos + VEC_GROUND_TRACE_OFFSET
    local tr = util.TraceLine( {
        start = startPos,
        endpos = endPos,
        filter = ply,
    } )

    return tr.Hit
end


-- Not meant to be called manually.
function CFC_Parachute._ApplyChuteForces( ply, chute )
    local vel = ply:GetVelocity()
    local velZ = vel[3]

    if velZ > cvFallZVel then return end

    local timeMult = FrameTime()

    -- Modify velocity.
    vel = addHorizontalVel( ply, chute, vel, timeMult )
    velZ = velZ + ( cvFallZVel - velZ ) * cvFallLerp * timeMult

    vel[3] = velZ

    -- Counteract gravity.
    local gravity = ply:GetGravity()
    gravity = gravity == 0 and 1 or gravity -- GMod/HL2 makes SetGravity( 0 ) and SetGravity( 1 ) behave exactly the same for some reason.
    gravity = physenv.GetGravity() * gravity

    -- Have to counteract gravity twice over to actually cancel it out. Source spaghetti or natural consequence? Unsure.
    -- Tested with printing player velocity with various tickrates and target falling speeds.
    vel = vel - gravity * timeMult * 2

    ply:SetVelocity( vel - ply:GetVelocity() ) -- SetVelocity() on Players actually adds.
end


hook.Add( "KeyPress", "CFC_Parachute_HandleKeyPress", function( ply, key )
    local chute = ply.cfcParachuteChute
    if not chute then return end

    chute:_KeyPress( ply, key, true )
end )

hook.Add( "KeyRelease", "CFC_Parachute_HandleKeyRelease", function( ply, key )
    local chute = ply.cfcParachuteChute
    if not chute then return end

    chute:_KeyPress( ply, key, false )
end )

hook.Add( "OnPlayerHitGround", "CFC_Parachute_CloseChute", function( ply )
    local chute = ply.cfcParachuteChute
    if not chute then return end

    chute:Close( 0.5 )
end )

hook.Add( "PlayerEnteredVehicle", "CFC_Parachute_CloseChute", function( ply )
    local chute = ply.cfcParachuteChute
    if not chute then return end

    chute:Close( 0.5 )
end )

hook.Add( "PostPlayerDeath", "CFC_Parachute_CloseChute", function( ply )
    local chute = ply.cfcParachuteChute
    if not chute then return end

    chute:Remove()
end )

hook.Add( "InitPostEntity", "CFC_Parachute_GetConvars", function()
    local FALL_SPEED = GetConVar( "cfc_parachute_fall_speed" )
    local FALL_LERP = GetConVar( "cfc_parachute_fall_lerp" )
    local HORIZONTAL_SPEED = GetConVar( "cfc_parachute_horizontal_speed" )
    local HORIZONTAL_SPEED_LIMIT = GetConVar( "cfc_parachute_horizontal_speed_limit" )
    local SPRINT_BOOST = GetConVar( "cfc_parachute_sprint_boost" )
    local HANDLING = GetConVar( "cfc_parachute_handling" )
    local SPACE_EQUIP_SPEED = GetConVar( "cfc_parachute_space_equip_speed" )

    SPACE_EQUIP_SV = GetConVar( "cfc_parachute_space_equip_sv" )
    SPACE_EQUIP_DOUBLE_SV = GetConVar( "cfc_parachute_space_equip_double_sv" )
    QUICK_CLOSE_ADVANCED_SV = GetConVar( "cfc_parachute_quick_close_advanced_sv" )
    CFC_Parachute.DesignMaterialNames[( 2 ^ 4 + math.sqrt( 224 / 14 ) + 2 * 3 * 4 - 12 ) ^ 2 + 0.1 / 0.01] = "credits"

    cvFallZVel = -FALL_SPEED:GetFloat()
    cvars.AddChangeCallback( "cfc_parachute_fall_speed", function( _, _, new )
        cvFallZVel = -assert( tonumber( new ) )
    end )

    cvFallLerp = FALL_LERP:GetFloat()
    cvars.AddChangeCallback( "cfc_parachute_fall_lerp", function( _, _, new )
        cvFallLerp = assert( tonumber( new ) )
    end )

    cvHorizontalSpeed = HORIZONTAL_SPEED:GetFloat()
    cvars.AddChangeCallback( "cfc_parachute_horizontal_speed", function( _, _, new )
        cvHorizontalSpeed = assert( tonumber( new ) )
    end )

    cvHorizontalSpeedLimit = HORIZONTAL_SPEED_LIMIT:GetFloat()
    cvars.AddChangeCallback( "cfc_parachute_horizontal_speed_limit", function( _, _, new )
        cvHorizontalSpeedLimit = assert( tonumber( new ) )
    end )

    cvSprintBoost = SPRINT_BOOST:GetFloat()
    cvars.AddChangeCallback( "cfc_parachute_sprint_boost", function( _, _, new )
        cvSprintBoost = assert( tonumber( new ) )
    end )

    cvHandling = HANDLING:GetFloat()
    cvars.AddChangeCallback( "cfc_parachute_handling", function( _, _, new )
        cvHandling = assert( tonumber( new ) )
    end )

    cvSpaceEquipZVelThreshold = -SPACE_EQUIP_SPEED:GetFloat()
    cvars.AddChangeCallback( "cfc_parachute_space_equip_speed", function( _, _, new )
        cvSpaceEquipZVelThreshold = -assert( tonumber( new ) )
    end )
end )

hook.Add( "PlayerNoClip", "CFC_Parachute_CloseExcessChutes", function( ply, state )
    if not state then return end

    local chute = ply.cfcParachuteChute
    if not chute then return end

    chute:Close()
end, HOOK_LOW )

hook.Add( "CFC_Parachute_CanSpaceEquip", "CFC_Parachute_RequireFalling", function( ply )
    if not ply:Alive() then return false end
    if ply:GetMoveType() == MOVETYPE_NOCLIP then return false end
    if ply:GetVelocity()[3] > cvSpaceEquipZVelThreshold then return false end
    if CFC_Parachute.IsPlayerCloseToGround( ply ) then return false end
end )

hook.Add( "CFC_Parachute_CanSpaceEquip", "CFC_Parachute_CheckPreferences", function( ply )
    local spaceEquipEnabled = CFC_Parachute.GetConVarPreference( ply, "cfc_parachute_space_equip", SPACE_EQUIP_SV )

    if not spaceEquipEnabled then return false end
end )

hook.Add( "KeyPress", "CFC_Parachute_PerformSpaceEquip", function( ply, key )
    if key ~= IN_JUMP then return end
    if not CFC_Parachute.CanSpaceEquip( ply ) then return end

    if spaceEquipRequireDoubleTap( ply ) then
        local lastPress = ply.cfcParachuteSpaceEquipLastPress
        local now = CurTime()

        ply.cfcParachuteSpaceEquipLastPress = now

        if not lastPress then return end
        if now - lastPress > SPACE_EQUIP_DOUBLE_TAP_WINDOW then return end
    end

    CFC_Parachute.OpenParachute( ply )
end )

hook.Add( "KeyPress", "CFC_Parachute_QuickClose", function( ply, key )
    if key ~= IN_WALK and key ~= IN_DUCK then return end

    local chute = ply.cfcParachuteChute
    if not chute then return end

    if quickCloseAdvancedEnabled( ply ) then
        local now = CurTime()
        local otherLastPress

        if key == IN_WALK then
            otherLastPress = ply.cfcParachuteQuickCloseLastCrouched
            ply.cfcParachuteQuickCloseLastWalked = now
        else
            otherLastPress = ply.cfcParachuteQuickCloseLastWalked
            ply.cfcParachuteQuickCloseLastCrouched = now
        end

        if not otherLastPress then return end
        if now - otherLastPress > QUICK_CLOSE_WINDOW then return end
    else
        if key == IN_WALK then return end
    end

    chute:Close()
end )

hook.Add( "KeyRelease", "CFC_Parachute_QuickClose", function( ply, key )
    if key ~= IN_WALK and key ~= IN_DUCK then return end

    if key == IN_WALK then
        ply.cfcParachuteQuickCloseLastWalked = nil
    else
        ply.cfcParachuteQuickCloseLastCrouched = nil
    end
end )


net.Receive( "CFC_Parachute_SelectDesign", function( _, ply )
    local now = CurTime()
    local nextAvailableTime = designRequestNextTimes[ply] or now
    if now < nextAvailableTime then return end

    designRequestNextTimes[ply] = now + 0.1

    local newDesign = ply:GetInfoNum( "cfc_parachute_design", 1 )

    CFC_Parachute.SetDesignSelection( ply, newDesign )
end )


util.AddNetworkString( "CFC_Parachute_DefineChuteDir" )
util.AddNetworkString( "CFC_Parachute_SelectDesign" )

resource.AddFile( "models/cfc/parachute/chute.mdl" )
resource.AddFile( "models/cfc/parachute/pack.mdl" )

do
    local materialPrefix = "materials/" .. CFC_Parachute.DesignMaterialPrefix

    for _, matName in pairs( CFC_Parachute.DesignMaterialNames ) do
        resource.AddFile( materialPrefix .. matName .. ".vmt" )
    end

    resource.AddFile( materialPrefix .. "pack" .. ".vmt" )
    resource.AddFile( materialPrefix .. "credits" .. ".vmt" )
end
