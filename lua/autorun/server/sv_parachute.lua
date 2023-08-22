CFC_Parachute = CFC_Parachute or {}

CFC_Parachute.DesignMaterials = false
CFC_Parachute.DesignMaterialNames = false
CFC_Parachute.DesignMaterialCount = 21 -- Default value for in case someone changes their design without anyone having spawned a parachute swep yet
CFC_Parachute.DesignMaterialSub = string.len( "models/cfc/parachute/parachute_" ) + 1

local UNSTABLE_SHOOT_LURCH_CHANCE
local UNSTABLE_SHOOT_DIRECTION_CHANGE_CHANCE
local UNSTABLE_MAX_FALL_LURCH
local FALL_SPEED
local FALL_SPEED_UNFURLED
local FALL_LERP
local HORIZONTAL_SPEED
local HORIZONTAL_SPEED_UNFURLED
local HORIZONTAL_SPEED_UNSTABLE
local HORIZONTAL_SPEED_LIMIT
local SPRINT_BOOST
local HANDLING

local DESIGN_MATERIALS
local DESIGN_MATERIAL_COUNT = CFC_Parachute.DesignMaterialCount
local DESIGN_REQUEST_BURST_LIMIT = 10
local DESIGN_REQUEST_BURST_DURATION = 3

local LFS_EXISTS
local LFS_AUTO_CHUTE_HEIGHT
local LFS_EJECT_LAUNCH_FORCE
local LFS_EJECT_LAUNCH_BIAS
local LFS_ENTER_RADIUS

local TRACE_HULL_SCALE_SIDEWAYS = Vector( 1.05, 1.05, 1.05 )
local TRACE_HULL_SCALE_DOWN = Vector( 0.95, 0.95, 0.01 )
local VEC_REMOVE_Z = Vector( 1, 1, 0 )
local VEC_ZERO = Vector( 0, 0, 0 )
local ANG_ZERO = Angle( 0, 0, 0 )
local VIEW_PUNCH_CHECK_INTERVAL = 0.25

local isValid = IsValid
local realTime = RealTime


local function mSign( x )
    if x == 0 then return 0 end
    if x > 0 then return 1 end
    return -1
end

-- Individually scales up the x and y axes so they each have magnitude >= min
-- Doesn't scale the whole vector at once since a tiny x could result in a huge y, etc
local function minBoundVector( vec, xMin, yMin )
    local x = vec[1]
    local y = vec[2]
    x = mSign( x ) * math.max( math.abs( x ), xMin )
    y = mSign( y ) * math.max( math.abs( y ), yMin )

    return Vector( x, y, vec[3] )
end

local function changeOwner( wep, ply )
    if not isValid( wep ) then return end
    if wep:GetClass() ~= "cfc_weapon_parachute" then return end

    timer.Simple( 0, function()
        if not isValid( wep ) or not wep.ChangeOwner then return end

        wep:ChangeOwner( ply )
    end )
end

--[[
    - Increases the magnitude of velAdd if it opposes vel.
    - Ultimately makes it faster to brake and change directions.
    - To reduce the number of square-root calls, velAdd should be given as a unit vector.
--]]
local function improveHandling( vel, velAdd )
    local velLength = vel:Length()

    if velLength == 0 then return velAdd end

    local dot = vel:Dot( velAdd )
    dot = dot / velLength -- Get dot product on 0-1 scale

    if dot >= 0 then return velAdd end

    local mult = math.max( -dot * HANDLING:GetFloat(), 1 )

    return velAdd * mult
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

local function getHorizontalSpeed( moveData, isUnfurled, isUnstableControl, ignoreSprint )
    local hSpeed = isUnstableControl and HORIZONTAL_SPEED_UNSTABLE:GetFloat() or
                   isUnfurled        and HORIZONTAL_SPEED_UNFURLED:GetFloat() or
                                         HORIZONTAL_SPEED:GetFloat()

    if not ignoreSprint and moveData:KeyDown( IN_SPEED ) then
        return hSpeed * SPRINT_BOOST:GetFloat()
    end

    return hSpeed
end

local function getHorizontalMoveVel( moveData )
    local hVelAdd = Vector( 0, 0, 0 )
    local ang = moveData:GetAngles()
    ang = Angle( 0, ang[2], ang[3] ) -- Force angle to be horizontal

    -- Forward/Backward
    if moveData:KeyDown( IN_FORWARD ) then
        if not moveData:KeyDown( IN_BACK ) then
            hVelAdd = hVelAdd + ang:Forward()
        end
    elseif moveData:KeyDown( IN_BACK ) then
        hVelAdd = hVelAdd - ang:Forward()
    end

    -- Right/Left
    if moveData:KeyDown( IN_MOVERIGHT ) then
        if not moveData:KeyDown( IN_MOVELEFT ) then
            hVelAdd = hVelAdd + ang:Right()
        end
    elseif moveData:KeyDown( IN_MOVELEFT ) then
        hVelAdd = hVelAdd - ang:Right()
    end

    return hVelAdd
end

local function addHorizontalVel( moveData, ply, vel, timeMult, isUnfurled, unstableDir )
    -- Acquire direction based on moveData
    local hVelAdd = getHorizontalMoveVel( moveData )

    -- Apply the additional velocity
    local hVelAddLength = hVelAdd:Length()

    if hVelAddLength ~= 0 then
        hVelAdd = improveHandling( vel, hVelAdd / hVelAddLength )
        vel = vel + hVelAdd * timeMult * getHorizontalSpeed( moveData, isUnfurled, unstableDir, false )
    end

    if unstableDir then
        vel = vel + unstableDir * timeMult * getHorizontalSpeed( moveData, isUnfurled, false, true )
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
    local now = realTime()
    local nextCheckTime = ply.cfcParachuteNextViewPunchCheck or now

    if nextCheckTime > now then return end

    local punchVelOld = ply.cfcParachuteViewPunchVel
    local punchVelNew = ply:GetViewPunchVelocity()

    ply.cfcParachuteNextViewPunchCheck = now + VIEW_PUNCH_CHECK_INTERVAL
    ply.cfcParachuteViewPunchVel = punchVelNew

    if punchVelNew == ANG_ZERO or punchVelNew ~= punchVelOld then return end

    ply:SetViewPunchVelocity( ANG_ZERO )
    ply.cfcParachuteViewPunchVel = nil
end

function CFC_Parachute.SetDesignSelection( ply, oldDesign, newDesign )
    if not isValid( ply ) then return end

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

    if isValid( wep ) then
        wep:ApplyChuteDesign()
    end
end

function CFC_Parachute.TrySetupLFS()
    if not LFS_EXISTS then return end

    LFS_AUTO_CHUTE_HEIGHT = CreateConVar( "cfc_parachute_lfs_eject_height", 500, { FCVAR_REPLICATED, FCVAR_ARCHIVE }, "The minimum height above the ground a player must be for LFS eject events to trigger (e.g. auto-parachute and rendezook launch).", 0, 50000 )
    LFS_EJECT_LAUNCH_FORCE = CreateConVar( "cfc_parachute_lfs_eject_launch_force", 1100, { FCVAR_REPLICATED, FCVAR_ARCHIVE }, "The upwards force applied to players when they launch out of an LFS plane.", 0, 50000 )
    LFS_EJECT_LAUNCH_BIAS = CreateConVar( "cfc_parachute_lfs_eject_launch_bias", 25, { FCVAR_REPLICATED, FCVAR_ARCHIVE }, "How many degrees the LFS eject launch should course-correct the player's trajectory to send them straight up, for if their plane is tilted.", 0, 90 )
    LFS_EJECT_STABILITY_TIME = CreateConVar( "cfc_parachute_lfs_eject_stability_time", 5, { FCVAR_REPLICATED, FCVAR_ARCHIVE }, "How many seconds a player is immune to parachute instability when they launch out of an LFS plane.", 0, 50000 )
    LFS_ENTER_RADIUS = CreateConVar( "cfc_parachute_lfs_enter_radius", 800, { FCVAR_REPLICATED, FCVAR_ARCHIVE }, "How close a player must be to enter an LFS if they are in a parachute and regular use detection fails. Makes it easier to get inside of an LFS for performing a Rendezook.", 0, 50000 )

    LFS_AUTO_CHUTE_SV = CreateConVar( "cfc_parachute_lfs_auto_equip_sv", 1, { FCVAR_ARCHIVE, FCVAR_REPLICATED }, "Whether or not to auto-equip a parachute when ejecting from an LFS plane in the air. Defines the default value for players.", 0, 1 )
    LFS_EJECT_LAUNCH_SV = CreateConVar( "cfc_parachute_lfs_eject_launch_sv", 1, { FCVAR_ARCHIVE, FCVAR_REPLICATED }, "Whether or not to launch up high when ejecting from an LFS plane in the air. Useful for pulling off a Rendezook. Defines the default value for players.", 0, 1 )

    hook.Add( "PlayerLeaveVehicle", "CFC_Parachute_LFSAirEject", function( ply, vehicle )
        if not isValid( ply ) or not ply:IsPlayer() or not ply:Alive() or not isValid( vehicle ) then return end

        local lfsPlane = vehicle.LFSBaseEnt

        if not isValid( lfsPlane ) then return end

        local minHeight = LFS_AUTO_CHUTE_HEIGHT:GetFloat()
        local canAutoChute

        if minHeight == 0 then
            canAutoChute = true
        else
            local hull = ply:OBBMaxs() * Vector( 1, 1, 0 ) + Vector( 0, 0, 1 )
            local plyPos = ply:GetPos()

            local mainEnts = { vehicle, lfsPlane, ply }
            local filterTable = constraint.GetAllConstrainedEntities( lfsPlane )

            for _, v in ipairs( mainEnts ) do
                table.insert( filterTable, v )
            end

            local tr = util.TraceHull( {
                start = plyPos,
                endpos = plyPos + Vector( 0, 0, -minHeight ),
                mins = -hull,
                maxs = hull,
                filter = filterTable,
            } )

            canAutoChute = not tr.Hit
        end

        if not canAutoChute then return end

        hook.Run( "CFC_Parachute_LFSAirEject", ply, vehicle, lfsPlane )
    end )

    hook.Add( "CFC_Parachute_LFSAirEject", "CFC_Parachute_LFSAutoChute", function( ply, vehicle, lfsPlane )
        if hook.Run( "CFC_Parachute_CanLFSAutoChute", ply, vehicle, lfsPlane ) == false then return end

        local wep = ply:GetWeapon( "cfc_weapon_parachute" )

        if not isValid( wep ) then
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

        timer.Simple( 0.1, function()
            if not isValid( ply ) then return end

            if ply:GetActiveWeapon() == wep then return end

            ply:SelectWeapon( "cfc_weapon_parachute" )
        end )

        timer.Simple( 0.2, function()
            if not isValid( ply ) or not isValid( wep ) then return end

            if ply:InVehicle() then
                wep:ChangeOpenStatus( false, ply )

                return
            end

            if wep.chuteIsOpen then return end

            wep:PrimaryAttack()
        end )
    end )

    hook.Add( "CFC_Parachute_LFSAirEject", "CFC_Parachute_LFSAutoLaunch", function( ply, vehicle, lfsPlane )
        if hook.Run( "CFC_Parachute_CanLFSEjectLaunch", ply, vehicle, lfsPlane ) == false then return end

        local force = LFS_EJECT_LAUNCH_FORCE:GetFloat()
        local bias = LFS_EJECT_LAUNCH_BIAS:GetFloat()

        local dir = lfsPlane:GetUp()

        if dir.z >= 0 then -- Biasing the direction if it's tilted down would be pointless
            local forwardAng = lfsPlane:GetAngles()
            local pitchCorrect = math.Clamp( forwardAng.p, -bias, bias )
            local rollCorrect = math.Clamp( -forwardAng.r, -bias, bias )

            forwardAng:RotateAroundAxis( lfsPlane:GetRight(), pitchCorrect )
            forwardAng:RotateAroundAxis( lfsPlane:GetForward(), rollCorrect )

            dir = forwardAng:Up()
        end

        timer.Simple( 0.01, function()
            if not isValid( ply ) then return end

            local lfsVel = isValid( lfsPlane ) and lfsPlane:GetVelocity() * 1.2 or Vector( 0, 0, 0 )

            ply:SetVelocity( dir * force + lfsVel )
        end )

        ply.cfcParachuteInstabilityImmune = true

        timer.Create( "CFC_Parachute_InstabilityImmuneTimeout_" .. ply:SteamID(), LFS_EJECT_STABILITY_TIME:GetFloat(), 1, function()
            if not isValid( ply ) then return end

            ply.cfcParachuteInstabilityImmune = false
        end )
    end )

    hook.Add( "CFC_Parachute_CanLFSAutoChute", "CFC_Parachute_CheckAutoEquipConVar", function( ply )
        local plyVal = ply:GetInfoNum( "cfc_parachute_lfs_auto_equip", 2 )

        if plyVal == 1 then return end
        if plyVal == 0 then return false end

        local serverDefault = LFS_AUTO_CHUTE_SV:GetString()

        if serverDefault == "0" then return false end
    end )

    hook.Add( "CFC_Parachute_CanLFSEjectLaunch", "CFC_Parachute_CheckEjectLaunchConVar", function( ply )
        local plyVal = ply:GetInfoNum( "cfc_parachute_lfs_eject_launch", 2 )

        if plyVal == 1 then return end
        if plyVal == 0 then return false end

        local serverDefault = LFS_EJECT_LAUNCH_SV:GetString()

        if serverDefault == "0" then return false end
    end )

    hook.Add( "FindUseEntity", "CFC_Parachute_LFSEasyEnter", function( ply, ent )
        if isValid( ent ) or not isValid( ply ) or not ply:IsPlayer() or ply:InVehicle() then return end

        local wep = ply:GetWeapon( "cfc_weapon_parachute" )

        if not isValid( wep ) or not wep.chuteIsOpen then return end

        local radiusSqr = LFS_ENTER_RADIUS:GetFloat() ^ 2
        local lfsPlanes = ents.FindByClass( "lunasflightschool_*" )
        local plyPos = ply:GetPos()

        for i = 1, #lfsPlanes do
            local plane = lfsPlanes[i]

            if plane.GetDriverSeat and plane:GetPos():DistToSqr( plyPos ) <= radiusSqr then -- Verify that it's not some other type of LFS entity
                return plane
            end
        end
    end )
end

hook.Add( "PlayerDroppedWeapon", "CFC_Parachute_ChangeOwner", function( ply, wep )
    if not isValid( wep ) then return end
    if wep:GetClass() ~= "cfc_weapon_parachute" then return end

    wep:ChangeOpenStatus( false, ply )
    changeOwner( wep, ply )
end )

hook.Add( "WeaponEquip", "CFC_Parachute_ChangeOwner", changeOwner )

hook.Add( "KeyPress", "CFC_Parachute_HandleKeyPress", function( ply, key )
    local wep = ply:GetWeapon( "cfc_weapon_parachute" )

    if not isValid( wep ) then return end

    wep:KeyPress( ply, key, true )
end )

hook.Add( "KeyRelease", "CFC_Parachute_HandleKeyRelease", function( ply, key )
    local wep = ply:GetWeapon( "cfc_weapon_parachute" )

    if not isValid( wep ) then return end

    wep:KeyPress( ply, key, false )
end )

hook.Add( "OnPlayerHitGround", "CFC_Parachute_CloseChute", function( ply )
    local wep = ply:GetWeapon( "cfc_weapon_parachute" )

    if not isValid( wep ) then return end

    wep:ChangeOpenStatus( false )
end )

hook.Add( "PlayerEnteredVehicle", "CFC_Parachute_CloseChute", function( ply )
    local wep = ply:GetWeapon( "cfc_weapon_parachute" )

    if not isValid( wep ) then return end

    wep:ChangeOpenStatus( false )

    timer.Simple( 0.1, function()
        if not isValid( wep ) then return end

        wep:ChangeOpenStatus( false )
    end )
end )

hook.Add( "Move", "CFC_Parachute_SlowFall", function( ply, moveData )
    if ply:GetMoveType() == MOVETYPE_NOCLIP then return end

    local wep = ply:GetWeapon( "cfc_weapon_parachute" )

    if not isValid( wep ) then return end
    if not wep.chuteIsOpen then return end

    local isUnfurled = wep.chuteIsUnfurled
    local isUnstable = wep.chuteIsUnstable
    local unstableDir
    local targetFallVel = -( isUnfurled and FALL_SPEED_UNFURLED:GetFloat() or FALL_SPEED:GetFloat() )
    local vel = moveData:GetVelocity()
    local velZ = vel[3]

    if velZ > targetFallVel then return end

    clearStuckViewPunch( ply )

    local timeMult = FrameTime()
    local lurch = wep.chuteLurch or 0

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
    vel = addHorizontalVel( moveData, ply, vel, timeMult, isUnfurled, unstableDir )
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

    if not isValid( owner ) then
        owner = data.Attacker
    end

    if not isValid( owner ) or not owner:IsPlayer() then return end

    local chuteSwep = owner:GetWeapon( "cfc_weapon_parachute" )

    if not isValid( chuteSwep ) or not chuteSwep.chuteIsUnstable then return end

    if math.Rand( 0, 1 ) <= UNSTABLE_SHOOT_LURCH_CHANCE:GetFloat() then
        chuteSwep:ApplyUnstableLurch()
    end

    if math.Rand( 0, 1 ) <= UNSTABLE_SHOOT_DIRECTION_CHANGE_CHANCE:GetFloat() then
        chuteSwep:ApplyUnstableDirectionChange()
    end
end )

hook.Add( "CFC_Parachute_ChuteCreated", "CFC_Parachute_DefineDesigns", function( chute )
    local designMaterials = CFC_Parachute.DesignMaterials

    if designMaterials then return end

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

hook.Add( "InitPostEntity", "CFC_Parachute_CheckOptionalDependencies", function()
    LFS_EXISTS = simfphys and simfphys.LFS and true

    CFC_Parachute.TrySetupLFS()
end )

hook.Add( "InitPostEntity", "CFC_Parachute_GetConvars", function()
    UNSTABLE_SHOOT_LURCH_CHANCE = GetConVar( "cfc_parachute_destabilize_shoot_lurch_chance" )
    UNSTABLE_SHOOT_DIRECTION_CHANGE_CHANCE = GetConVar( "cfc_parachute_destabilize_shoot_change_chance" )
    UNSTABLE_MAX_FALL_LURCH = GetConVar( "cfc_parachute_destabilize_max_fall_lurch" )
    FALL_SPEED = GetConVar( "cfc_parachute_fall_speed" )
    FALL_SPEED_UNFURLED = GetConVar( "cfc_parachute_fall_speed_unfurled" )
    FALL_LERP = GetConVar( "cfc_parachute_fall_lerp" )
    HORIZONTAL_SPEED = GetConVar( "cfc_parachute_horizontal_speed" )
    HORIZONTAL_SPEED_UNFURLED = GetConVar( "cfc_parachute_horizontal_speed_unfurled" )
    HORIZONTAL_SPEED_UNSTABLE = GetConVar( "cfc_parachute_horizontal_speed_unstable" )
    HORIZONTAL_SPEED_LIMIT = GetConVar( "cfc_parachute_horizontal_speed_limit" )
    SPRINT_BOOST = GetConVar( "cfc_parachute_sprint_boost" )
    HANDLING = GetConVar( "cfc_parachute_handling" )
end )

hook.Add( "PlayerNoClip", "CFC_Parachute_CloseExcessChutes", function( ply, state )
    if not state then return end

    local wep = ply:GetWeapon( "cfc_weapon_parachute" )

    if not isValid( wep ) or wep == ply:GetActiveWeapon() then return end

    wep:ChangeOpenStatus( false, ply )
end, HOOK_LOW )

net.Receive( "CFC_Parachute_SelectDesign", function( _, ply )
    if not isValid( ply ) then return end

    local requestCount = ( ply.cfcParachuteDesignRequests or 0 ) + 1

    if requestCount > DESIGN_REQUEST_BURST_LIMIT then return end

    if requestCount == 1 then
        timer.Simple( DESIGN_REQUEST_BURST_DURATION, function()
            if not isValid( ply ) then return end

            ply.cfcParachuteDesignRequests = nil
        end )
    end

    ply.cfcParachuteDesignRequests = requestCount

    local oldDesign = net.ReadInt( 17 ) or 1
    local newDesign = net.ReadInt( 17 ) or 1

    CFC_Parachute.SetDesignSelection( ply, oldDesign, newDesign )
end )

util.AddNetworkString( "CFC_Parachute_DefineChuteDir" )
util.AddNetworkString( "CFC_Parachute_DefineChuteUnfurlStatus" )
util.AddNetworkString( "CFC_Parachute_GrabChuteStraps" )
util.AddNetworkString( "CFC_Parachute_DefineDesigns" )
util.AddNetworkString( "CFC_Parachute_SelectDesign" )
