CFC_Parachute = CFC_Parachute or {}

CFC_Parachute.DesignMaterials = false
CFC_Parachute.DesignMaterialNames = false
CFC_Parachute.DesignMaterialCount = 21 -- Default value for in case someone changes their design without anyone having spawned a parachute swep yet
CFC_Parachute.DesignMaterialSub = string.len( "models/cfc/parachute/parachute_" ) + 1

-- Convars
local UNSTABLE_SHOOT_LURCH_CHANCE
local UNSTABLE_SHOOT_DIRECTION_CHANGE_CHANCE
local UNSTABLE_MAX_FALL_LURCH
local FALL_SPEED
local FALL_LERP
local HORIZONTAL_SPEED
local HORIZONTAL_SPEED_UNSTABLE
local HORIZONTAL_SPEED_LIMIT
local SPRINT_BOOST
local HANDLING
local SPACE_EQUIP_SPEED
local SPACE_EQUIP_SV
local SPACE_EQUIP_DOUBLE_SV
local SPACE_EQUIP_WEAPON_SV
local QUICK_CLOSE_SV

-- Chute designs
local DESIGN_MATERIALS
local DESIGN_MATERIAL_COUNT = CFC_Parachute.DesignMaterialCount
local DESIGN_REQUEST_BURST_LIMIT = 10
local DESIGN_REQUEST_BURST_DURATION = 3

-- Misc
local TRACE_HULL_SCALE_SIDEWAYS = Vector( 1.05, 1.05, 1.05 )
local TRACE_HULL_SCALE_DOWN = Vector( 0.95, 0.95, 0.01 )
local VEC_REMOVE_Z = Vector( 1, 1, 0 )
local VEC_ZERO = Vector( 0, 0, 0 )
local ANG_ZERO = Angle( 0, 0, 0 )
local VIEW_PUNCH_CHECK_INTERVAL = 0.25
local SPACE_EQUIP_DOUBLE_TAP_WINDOW = 0.35
local QUICK_CLOSE_WINDOW = 0.35

local IsValid = IsValid
local RealTime = RealTime


local function mathSign( x )
    if x == 0 then return 0 end
    if x > 0 then return 1 end

    return -1
end

-- Individually scales up the x and y axes so they each have magnitude >= min
-- Doesn't scale the whole vector at once, otherwise a tiny x could result in a huge y, etc
local function minBoundVector( vec, xMin, yMin )
    local x = vec[1]
    local y = vec[2]
    x = mathSign( x ) * math.max( math.abs( x ), xMin )
    y = mathSign( y ) * math.max( math.abs( y ), yMin )

    return Vector( x, y, vec[3] )
end

local function changeOwner( wep, ply )
    if not IsValid( wep ) then return end
    if wep:GetClass() ~= "cfc_weapon_parachute" then return end

    timer.Simple( 0, function()
        if not IsValid( wep ) or not wep.ChangeOwner then return end

        wep:ChangeOwner( ply )
    end )
end

-- uses a TraceLine to see if a velocity does NOT clip into a wall when we don't know the wall's position or normal
local function velLeavesCloseWall( ply, startPos, velHorizEff )
    -- Small inwards velocities pass due to being short, so we need to extend the length
    local minBoundExtra = 2
    local minBounds = ply:OBBMaxs() + Vector( minBoundExtra, minBoundExtra, 0 )

    local tr = util.TraceLine( {
        start = startPos,
        endpos = startPos + minBoundVector( velHorizEff, minBounds[1], minBounds[2] ),
        filter = ply,
    } )

    return not tr.Hit
end

-- Ensures the move velocity doesn't cause a player to clip into a wall
local function verifyVel( moveData, ply, vel, timeMult )
    if timeMult == 0 then return vel end

    local startPos = moveData:GetOrigin()
    local velVert = Vector( 0, 0, vel[3] ) -- Keep track of z-vel since this func should only modify the horizontal portion
    local velHoriz = vel - velVert
    local tr = util.TraceHull( {
        start = startPos,
        endpos = startPos + velHoriz * timeMult,
        mins = ply:OBBMins() * TRACE_HULL_SCALE_SIDEWAYS,
        maxs = ply:OBBMaxs() * TRACE_HULL_SCALE_SIDEWAYS,
        filter = ply,
    } )

    if tr.Hit then
        local norm = tr.HitNormal

        -- Leave things be if vel would bring us away from the wall
        if norm:Dot( velHoriz ) > 0 then return vel end

        local traceDiff = tr.HitPos - startPos

        -- If the player is *right* up against a wall, we need a second trace to know if vel faces towards or away from the wall
        if norm == VEC_ZERO and traceDiff == VEC_ZERO then
            local velIsGood = velLeavesCloseWall( ply, startPos, velHoriz * timeMult )
            if velIsGood then return vel end
        end

        vel = traceDiff * VEC_REMOVE_Z + velVert
    end

    return vel
end

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

    local mult = math.max( -dot * HANDLING:GetFloat(), 1 )

    return moveDir * mult
end

local function getHorizontalMoveSpeed( moveData, isUnstable )
    local hSpeed =
        isUnstable and HORIZONTAL_SPEED_UNSTABLE:GetFloat() or
                       HORIZONTAL_SPEED:GetFloat()

    if moveData:KeyDown( IN_SPEED ) then
        return hSpeed * SPRINT_BOOST:GetFloat()
    end

    return hSpeed
end

local function getHorizontalMoveDir( moveData )
    local hDir = Vector( 0, 0, 0 )
    local ang = moveData:GetAngles()
    local isNonZero = false
    ang = Angle( 0, ang[2], ang[3] ) -- Force angle to be horizontal

    -- Forward/Backward
    if moveData:KeyDown( IN_FORWARD ) then
        if not moveData:KeyDown( IN_BACK ) then
            hDir = hDir + ang:Forward()
            isNonZero = true
        end
    elseif moveData:KeyDown( IN_BACK ) then
        hDir = hDir - ang:Forward()
        isNonZero = true
    end

    -- Right/Left
    if moveData:KeyDown( IN_MOVERIGHT ) then
        if not moveData:KeyDown( IN_MOVELEFT ) then
            hDir = hDir + ang:Right()
            isNonZero = true
        end
    elseif moveData:KeyDown( IN_MOVELEFT ) then
        hDir = hDir - ang:Right()
        isNonZero = true
    end

    if isNonZero then
        hDir:Normalize()
    end

    return hDir, isNonZero
end

local function addHorizontalVel( moveData, ply, vel, timeMult, unstableDir )
    -- Acquire direction based on moveData
    local hDir, hDirIsNonZero = getHorizontalMoveDir( moveData )

    -- Add movement velocity (WASD control)
    if hDirIsNonZero then
        hDir = improveHandling( vel, hDir )
        vel = vel + hDir * timeMult * getHorizontalMoveSpeed( moveData, unstableDir )
    end

    -- Add unstable velocity
    if unstableDir then
        vel = vel + unstableDir * timeMult * HORIZONTAL_SPEED:GetFloat()
    end

    -- Limit the horizontal speed
    local hSpeedCur = vel:Length2D()
    local hSpeedLimit = HORIZONTAL_SPEED_LIMIT:GetFloat()

    if hSpeedCur > hSpeedLimit then
        local mult = hSpeedLimit / hSpeedCur

        vel[1] = vel[1] * mult
        vel[2] = vel[2] * mult
    end

    vel = verifyVel( moveData, ply, vel, timeMult )

    return vel
end

-- Ensures large amounts of lurch doesn't cause the player to clip through the floor
local function verifyLurch( moveData, ply, timeMult, velZ, lurch )
    if lurch >= 0 then return lurch end
    if math.abs( velZ ) >= UNSTABLE_MAX_FALL_LURCH:GetFloat() then return 0 end

    if timeMult == 0 then
        timeMult = 0.03
    end

    local startHoist = 5 -- Raises the startPos for in case ply is already starting to clip into the floor
    local traceExtend = 4 -- Extends the trace so we can check for shortly beyond where velZ and lurch will place the player
    local startPos = moveData:GetOrigin() + Vector( 0, 0, startHoist )
    local traceLength = math.abs( velZ * timeMult + lurch ) + traceExtend + startHoist

    local tr = util.TraceHull( {
        start = startPos,
        endpos = startPos + Vector( 0, 0, -traceLength ),
        mins = ply:OBBMins() * TRACE_HULL_SCALE_DOWN,
        maxs = ply:OBBMaxs() * TRACE_HULL_SCALE_DOWN,
        filter = ply,
    } )

    if not tr.Hit then return lurch end

    local hitLength = traceLength * tr.Fraction - startHoist -- Distance from moveOrigin to hitPos
    local extraBuffer = 2.5 / timeMult -- Try to end up slightly above the floor, for just in case
    local lurchUpLimit = extraBuffer / 2 -- Don't yield a positive (upwards) lurch beyond this value
    local amountToRemove = traceLength - hitLength + extraBuffer

    return math.min( lurchUpLimit, lurch + amountToRemove )
end

-- Messing with the Move hook causes view punch velocity to sometimes get stuck while in a parachute.
-- This periodically checks and clears out view punch when it gets stuck.
local function clearStuckViewPunch( ply )
    local now = RealTime()
    local nextCheckTime = ply.cfcParachuteNextViewPunchCheck or now
    if nextCheckTime > now then return end

    local punchVelOld = ply.cfcParachuteViewPunchVel
    local punchVelNew = ply:GetViewPunchVelocity()

    ply.cfcParachuteNextViewPunchCheck = now + VIEW_PUNCH_CHECK_INTERVAL
    ply.cfcParachuteViewPunchVel = punchVelNew

    if punchVelNew == ANG_ZERO then return end
    if punchVelNew ~= punchVelOld then return end

    ply:SetViewPunchVelocity( ANG_ZERO )
    ply.cfcParachuteViewPunchVel = nil
end

local function spaceEquipEnabled( ply )
    return CFC_Parachute.GetConVarPreference( ply, "cfc_parachute_space_equip", SPACE_EQUIP_SV )
end

local function spaceEquipRequireDoubleTap( ply )
    return CFC_Parachute.GetConVarPreference( ply, "cfc_parachute_space_equip_double", SPACE_EQUIP_DOUBLE_SV )
end

local function spaceEquipShouldEquipWeapon( ply )
    return CFC_Parachute.GetConVarPreference( ply, "cfc_parachute_space_equip_weapon", SPACE_EQUIP_WEAPON_SV )
end

local function quickCloseEnabled( ply )
    return CFC_Parachute.GetConVarPreference( ply, "cfc_parachute_quick_close", QUICK_CLOSE_SV )
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

function CFC_Parachute.SetDesignSelection( ply, oldDesign, newDesign )
    if not IsValid( ply ) then return end

    oldDesign = oldDesign or 1
    newDesign = newDesign or 1

    local originalNewDesign = newDesign

    if not DESIGN_MATERIALS then
        if newDesign < 1 or newDesign > DESIGN_MATERIAL_COUNT or math.floor( newDesign ) ~= newDesign then
            newDesign = oldDesign

            if newDesign < 1 or newDesign > DESIGN_MATERIAL_COUNT or math.floor( newDesign ) ~= newDesign then
                newDesign = 1
            end
        end
    else
        if not DESIGN_MATERIALS[newDesign] then
            newDesign = oldDesign

            if not DESIGN_MATERIALS[newDesign] then
                newDesign = 1
            end
        end
    end

    if originalNewDesign ~= newDesign then
        ply:ConCommand( "cfc_parachute_design " .. newDesign )

        return
    end

    ply.cfcParachuteDesignID = newDesign

    local wep = ply:GetWeapon( "cfc_weapon_parachute" )

    if IsValid( wep ) then
        wep:ApplyChuteDesign()
    end
end

function CFC_Parachute.EquipAndOpenParachute( ply )
    if not IsValid( ply ) then return end

    local wep = ply:GetWeapon( "cfc_weapon_parachute" )

    if not IsValid( wep ) then
        wep = ents.Create( "cfc_weapon_parachute" )
        wep:SetPos( Vector( 0, 0, 0 ) )
        wep:SetOwner( ply )
        wep:Spawn()

        if hook.Run( "PlayerCanPickupWeapon", ply, wep ) == false then
            wep:Remove()

            return
        end

        ply:PickupWeapon( wep )
    end

    timer.Simple( 0.05, function()
        if not IsValid( ply ) then return end
        if ply:GetActiveWeapon() == wep then return end

        ply:SelectWeapon( "cfc_weapon_parachute" )
    end )

    timer.Simple( 0.1, function()
        if not IsValid( ply ) or not IsValid( wep ) then return end

        if ply:InVehicle() then
            wep:ChangeOpenStatus( false, ply )

            return
        end

        if wep.chuteIsOpen then return end

        wep:PrimaryAttack()
    end )
end

--[[
    - Sets whether or not a player is ready to use space-equip.
    - You can block the player from becoming ready by returning false in the CFC_Parachute_SpaceEquipCanReady hook.
        - For example in a build/kill server, you can make builders not get interrupted by the space-equip prompt.
        - It's recommended to not block if IsValid( ply:GetWeapon( "cfc_weapon_parachute" ) ) is true, however.
            - Otherwise, a player who manually equipped the SWEP won't be able to use spacebar as a shortcut to open the chute.
--]]
function CFC_Parachute.SetSpaceEquipReadySilent( ply, state )
    if not IsValid( ply ) then return end
    if ply.cfcParachuteSpaceEquipReady == state then return end
    if state and hook.Run( "CFC_Parachute_SpaceEquipCanReady", ply ) == false then return end

    ply.cfcParachuteSpaceEquipReady = state
    ply.cfcParachuteSpaceEquipLastPress = nil
end

-- Same as CFC_Parachute.SetSpaceEquipReady() but also tells the client to play the ready sound, if applicable.
function CFC_Parachute.SetSpaceEquipReady( ply, state )
    if not IsValid( ply ) then return end
    if ply.cfcParachuteSpaceEquipReady == state then return end

    CFC_Parachute.SetSpaceEquipReadySilent( ply, state )

    if ply.cfcParachuteSpaceEquipReady then
        net.Start( "CFC_Parachute_SpaceEquipReady" )
        net.Send( ply )
    end
end


hook.Add( "PlayerDroppedWeapon", "CFC_Parachute_ChangeOwner", function( ply, wep )
    if not IsValid( wep ) then return end
    if wep:GetClass() ~= "cfc_weapon_parachute" then return end

    wep:ChangeOpenStatus( false, ply )
    changeOwner( wep, ply )
end )

hook.Add( "WeaponEquip", "CFC_Parachute_ChangeOwner", changeOwner )

hook.Add( "KeyPress", "CFC_Parachute_HandleKeyPress", function( ply, key )
    local wep = ply:GetWeapon( "cfc_weapon_parachute" )
    if not IsValid( wep ) then return end

    wep:KeyPress( ply, key, true )
end )

hook.Add( "KeyRelease", "CFC_Parachute_HandleKeyRelease", function( ply, key )
    local wep = ply:GetWeapon( "cfc_weapon_parachute" )
    if not IsValid( wep ) then return end

    wep:KeyPress( ply, key, false )
end )

hook.Add( "OnPlayerHitGround", "CFC_Parachute_CloseChute", function( ply )
    local wep = ply:GetWeapon( "cfc_weapon_parachute" )
    if not IsValid( wep ) then return end

    wep:ChangeOpenStatus( false )
end )

hook.Add( "PlayerEnteredVehicle", "CFC_Parachute_CloseChute", function( ply )
    local wep = ply:GetWeapon( "cfc_weapon_parachute" )
    if not IsValid( wep ) then return end

    wep:ChangeOpenStatus( false )

    timer.Simple( 0.1, function()
        if not IsValid( wep ) then return end

        wep:ChangeOpenStatus( false )
    end )
end )

hook.Add( "Move", "CFC_Parachute_SlowFall", function( ply, moveData )
    if ply:GetMoveType() == MOVETYPE_NOCLIP then return end

    local wep = ply:GetWeapon( "cfc_weapon_parachute" )
    if not IsValid( wep ) then return end
    if not wep.chuteIsOpen then return end

    local targetFallVel = -FALL_SPEED:GetFloat()
    local vel = moveData:GetVelocity()
    local velZ = vel[3]

    if velZ > targetFallVel then return end

    clearStuckViewPunch( ply )

    local timeMult = FrameTime()
    local lurch = wep.chuteLurch or 0
    local isUnstable = wep.chuteIsUnstable
    local unstableDir = false

    -- Ensure we maintain the locked angle for unstable parachutes
    if isUnstable then
        local lockedAng = wep.chuteDirAng

        if not lockedAng then
            lockedAng = moveData:GetAngles()
            lockedAng = Angle( 0, ang[2], ang[3] ) -- Force angle to be horizontal

            wep.chuteDirAng = lockedAng
        end

        unstableDir = lockedAng:Forward()
    end

    -- Modify velocity
    vel = addHorizontalVel( moveData, ply, vel, timeMult, unstableDir )
    velZ = velZ + ( targetFallVel - velZ ) * FALL_LERP:GetFloat() * timeMult

    if lurch ~= 0 then
        lurch = verifyLurch( moveData, ply, timeMult, velZ, lurch )
        vel[3] = velZ + lurch
        wep.chuteLurch = 0
    else
        vel[3] = velZ
    end

    moveData:SetVelocity( vel )
    moveData:SetOrigin( moveData:GetOrigin() + vel * timeMult )

    return true
end )

hook.Add( "EntityFireBullets", "CFC_Parachute_UnstableShoot", function( ent, data )
    local owner = ent:GetOwner()
    owner = IsValid( owner ) and owner or data.Attacker

    if not IsValid( owner ) then return end
    if not owner:IsPlayer() then return end

    local chuteSwep = owner:GetWeapon( "cfc_weapon_parachute" )
    if not IsValid( chuteSwep ) then return end
    if not chuteSwep.chuteIsUnstable then return end

    if math.Rand( 0, 1 ) <= UNSTABLE_SHOOT_LURCH_CHANCE:GetFloat() then
        chuteSwep:ApplyUnstableLurch()
    end

    if math.Rand( 0, 1 ) <= UNSTABLE_SHOOT_DIRECTION_CHANGE_CHANCE:GetFloat() then
        chuteSwep:ApplyUnstableDirectionChange()
    end
end )

hook.Add( "CFC_Parachute_ChuteCreated", "CFC_Parachute_DefineDesigns", function( chute )
    local designMaterials = CFC_Parachute.DesignMaterials
    if designMaterials then return end -- Already defined

    designMaterials = chute:GetMaterials()
    designMaterialNames = {}

    local designMaterialCount = #designMaterials - 1
    local designMaterialSub = CFC_Parachute.DesignMaterialSub

    table.remove( designMaterials, 2 )

    designMaterials[1034] = designMaterials[designMaterialCount]
    designMaterialNames[1034] = designMaterials[1034]:sub( designMaterialSub )
    designMaterials[designMaterialCount] = nil

    designMaterialCount = designMaterialCount - 1

    for i = 1, designMaterialCount do
        designMaterialNames[i] = designMaterials[i]:sub( designMaterialSub )
    end

    CFC_Parachute.DesignMaterials = designMaterials
    CFC_Parachute.DesignMaterialNames = designMaterialNames
    CFC_Parachute.DesignMaterialCount = designMaterialCount

    DESIGN_MATERIALS = designMaterials
    DESIGN_MATERIAL_NAMES = designMaterialNames
    DESIGN_MATERIAL_COUNT = designMaterialCount
end )

hook.Add( "InitPostEntity", "CFC_Parachute_GetConvars", function()
    UNSTABLE_SHOOT_LURCH_CHANCE = GetConVar( "cfc_parachute_destabilize_shoot_lurch_chance" )
    UNSTABLE_SHOOT_DIRECTION_CHANGE_CHANCE = GetConVar( "cfc_parachute_destabilize_shoot_change_chance" )
    UNSTABLE_MAX_FALL_LURCH = GetConVar( "cfc_parachute_destabilize_max_fall_lurch" )
    FALL_SPEED = GetConVar( "cfc_parachute_fall_speed" )
    FALL_LERP = GetConVar( "cfc_parachute_fall_lerp" )
    HORIZONTAL_SPEED = GetConVar( "cfc_parachute_horizontal_speed" )
    HORIZONTAL_SPEED_UNSTABLE = GetConVar( "cfc_parachute_horizontal_speed_unstable" )
    HORIZONTAL_SPEED_LIMIT = GetConVar( "cfc_parachute_horizontal_speed_limit" )
    SPRINT_BOOST = GetConVar( "cfc_parachute_sprint_boost" )
    HANDLING = GetConVar( "cfc_parachute_handling" )
    SPACE_EQUIP_SPEED = GetConVar( "cfc_parachute_space_equip_speed" )
    SPACE_EQUIP_SV = GetConVar( "cfc_parachute_space_equip_sv" )
    SPACE_EQUIP_DOUBLE_SV = GetConVar( "cfc_parachute_space_equip_double_sv" )
    SPACE_EQUIP_WEAPON_SV = GetConVar( "cfc_parachute_space_equip_weapon_sv" )
    QUICK_CLOSE_SV = GetConVar( "cfc_parachute_quick_close_sv" )
end )

hook.Add( "PlayerNoClip", "CFC_Parachute_CloseExcessChutes", function( ply, state )
    if not state then return end

    local wep = ply:GetWeapon( "cfc_weapon_parachute" )
    if not IsValid( wep ) then return end
    if wep == ply:GetActiveWeapon() then return end

    wep:ChangeOpenStatus( false, ply )
end, HOOK_LOW )

hook.Add( "Think", "CFC_Parachute_SpaceEquipCheck", function()
    local zVelThreshold = -SPACE_EQUIP_SPEED:GetFloat()

    for _, ply in ipairs( player.GetAll() ) do
        local wep = ply:GetWeapon( "cfc_weapon_parachute" )
        if IsValid( wep ) then continue end -- Already have a parachute, no need to check.

        local zVel = ply:GetVelocity()[3]

        if ply.cfcParachuteSpaceEquipReady then
            if ply:GetMoveType() == MOVETYPE_NOCLIP or zVel > zVelThreshold then
                CFC_Parachute.SetSpaceEquipReady( ply, false )
            end
        else
            if ply:GetMoveType() ~= MOVETYPE_NOCLIP and zVel <= zVelThreshold then
                CFC_Parachute.SetSpaceEquipReady( ply, true )
            end
        end
    end
end )

hook.Add( "CFC_Parachute_SpaceEquipCanReady", "CFC_Parachute_CheckPreferences", function( ply )
    if not spaceEquipEnabled( ply ) then return false end
end )

hook.Add( "KeyPress", "CFC_Parachute_PerformSpaceEquip", function( ply, key )
    if not ply.cfcParachuteSpaceEquipReady then return end
    if ply:GetMoveType() == MOVETYPE_NOCLIP then return end -- Always ignore if the player is in noclip, regardless of ready status.
    if key ~= IN_JUMP then return end

    if spaceEquipRequireDoubleTap( ply ) then
        local lastPress = ply.cfcParachuteSpaceEquipLastPress
        local now = RealTime()

        ply.cfcParachuteSpaceEquipLastPress = now

        if not lastPress then return end
        if now - lastPress > SPACE_EQUIP_DOUBLE_TAP_WINDOW then return end
    end

    local chuteWep = ply:GetWeapon( "cfc_weapon_parachute" )

    -- If the player is holding a parachute, space-equip is just a shortcut to opening it.
    if IsValid( chuteWep ) then
        chuteWep:ChangeOpenStatus( true )

        return
    end

    local prevWep = ply:GetActiveWeapon()

    CFC_Parachute.EquipAndOpenParachute( ply )

    if spaceEquipShouldEquipWeapon( ply ) then
        timer.Simple( 0.15, function()
            if not IsValid( ply ) then return end
            if not IsValid( prevWep ) then return end

            ply:SelectWeapon( prevWep:GetClass() )
        end )
    end
end )

hook.Add( "KeyPress", "CFC_Parachute_QuickClose", function( ply, key )
    if key ~= IN_WALK and key ~= IN_DUCK then return end

    local now = RealTime()
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
    if not quickCloseEnabled( ply ) then return end

    local wep = ply:GetWeapon( "cfc_weapon_parachute" )
    if not IsValid( wep ) then return end

    wep:ChangeOpenStatus( false )
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
    if not IsValid( ply ) then return end

    local requestCount = ( ply.cfcParachuteDesignRequests or 0 ) + 1
    if requestCount > DESIGN_REQUEST_BURST_LIMIT then return end

    if requestCount == 1 then
        timer.Simple( DESIGN_REQUEST_BURST_DURATION, function()
            if not IsValid( ply ) then return end

            ply.cfcParachuteDesignRequests = nil
        end )
    end

    ply.cfcParachuteDesignRequests = requestCount

    local oldDesign = net.ReadInt( 17 ) or 1
    local newDesign = net.ReadInt( 17 ) or 1

    CFC_Parachute.SetDesignSelection( ply, oldDesign, newDesign )
end )

net.Receive( "CFC_Parachute_SpaceEquipUpdatePreferences", function( _, ply )
    if not IsValid( ply ) then return end
    if not IsValid( ply:GetWeapon( "cfc_weapon_parachute" ) ) then return end -- Think hook will auto-update for us if they don't have a parachute.

    -- When a player has a parachute equipped, it should always have SE ready if player/server preferences allow.
    -- So, silently set to false and then true, the latter of which will get blocked if preferences don't allow it.
    CFC_Parachute.SetSpaceEquipReadySilent( ply, false )
    CFC_Parachute.SetSpaceEquipReadySilent( ply, true )
end )


util.AddNetworkString( "CFC_Parachute_DefineChuteDir" )
util.AddNetworkString( "CFC_Parachute_GrabChuteStraps" )
util.AddNetworkString( "CFC_Parachute_DefineDesigns" )
util.AddNetworkString( "CFC_Parachute_SelectDesign" )
util.AddNetworkString( "CFC_Parachute_SpaceEquipReady" )
util.AddNetworkString( "CFC_Parachute_SpaceEquipUpdatePreferences" )