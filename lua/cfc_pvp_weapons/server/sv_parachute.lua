CFC_Parachute = CFC_Parachute or {}

-- Convars
local SPACE_EQUIP_SV
local SPACE_EQUIP_DOUBLE_SV
local SPACE_EQUIP_REDUNDANCY_SV
local SPACE_EQUIP_WEAPON_SV
local QUICK_CLOSE_SV
local QUICK_CLOSE_ADVANCED_SV

-- Convar value localizations
local cvUnstableShootLurchChance
local cvUnstableShootDirectionChangeChance
local cvUnstableMaxFallLurch
local cvFallZVel
local cvFallLerp
local cvHorizontalSpeed
local cvHorizontalSpeedUnstable
local cvHorizontalSpeedLimit
local cvSprintBoost
local cvHandling
local cvSpaceEquipZVelThreshold

-- Chute designs
local DESIGN_REQUEST_BURST_LIMIT = 10
local DESIGN_REQUEST_BURST_DURATION = 3

-- Misc
local VEC_ZERO = Vector( 0, 0, 0 )
local SPACE_EQUIP_DOUBLE_TAP_WINDOW = 0.35
local QUICK_CLOSE_WINDOW = 0.35

local IsValid = IsValid
local RealTime = RealTime


local function changeOwner( wep, ply )
    if not IsValid( wep ) then return end
    if wep:GetClass() ~= "cfc_weapon_parachute" then return end

    timer.Simple( 0, function()
        if not IsValid( wep ) or not wep.ChangeOwner then return end

        wep:ChangeOwner( ply )
    end )
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

    local mult = math.max( -dot * cvHandling, 1 )

    return moveDir * mult
end

local function getHorizontalMoveSpeed( ply, isUnstable )
    if isUnstable then return cvHorizontalSpeedUnstable end

    local hSpeed = cvHorizontalSpeed

    if ply:KeyDown( IN_SPEED ) then
        return hSpeed * cvSprintBoost
    end

    return hSpeed
end

-- Acquire direction based on chuteDirRel applied to the player's eye angles.
local function getHorizontalMoveDir( ply, chuteWep )
    local chuteDirRel = chuteWep.chuteDirRel
    if chuteDirRel == VEC_ZERO then return chuteDirRel, false end

    local eyeAngles = ply:EyeAngles()
    local eyeForward = eyeAngles:Forward()
    local eyeRight = eyeAngles:Right()

    local moveDir = ( eyeForward * chuteDirRel.x + eyeRight * chuteDirRel.y ) * Vector( 1, 1, 0 )
    moveDir:Normalize()

    return moveDir, true
end

local function addHorizontalVel( ply, chuteWep, vel, timeMult, unstableDir )
    -- Acquire player's desired movement direction
    local hDir, hDirIsNonZero = getHorizontalMoveDir( ply, chuteWep )

    -- Add movement velocity (WASD control)
    if hDirIsNonZero then
        hDir = improveHandling( vel, hDir )
        vel = vel + hDir * timeMult * getHorizontalMoveSpeed( ply, unstableDir )
    end

    -- Add unstable velocity
    if unstableDir then
        vel = vel + unstableDir * timeMult * cvHorizontalSpeed
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

-- Enforces lurch limits according to convars.
local function verifyLurch( velZ, lurch )
    if lurch >= 0 then return lurch end
    if math.abs( velZ ) >= cvUnstableMaxFallLurch then return 0 end

    return lurch
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

function CFC_Parachute.SetDesignSelection( ply, oldDesign, newDesign )
    if not IsValid( ply ) then return end

    oldDesign = oldDesign or 1
    newDesign = newDesign or 1

    local originalNewDesign = newDesign
    local designMaterialNames = CFC_Parachute.DesignMaterialNames

    -- Validate new design, reverting to and validating the old design if necessary.
    if not designMaterialNames[newDesign] then
        newDesign = oldDesign

        if not designMaterialNames[newDesign] then
            newDesign = 1
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

    -- Weapon is valid, select and open it.
    if IsValid( wep ) then
        if ply:GetActiveWeapon() ~= wep then
            ply:SelectWeapon( "cfc_weapon_parachute" )
        end

        wep:ChangeOpenStatus( true )

        return
    end

    -- Spawn parachute SWEP
    wep = ents.Create( "cfc_weapon_parachute" )
    wep:SetPos( Vector( 0, 0, 0 ) )
    wep:SetOwner( ply )
    wep:Spawn()

    if hook.Run( "PlayerCanPickupWeapon", ply, wep ) == false then
        wep:Remove()

        return
    end

    ply:PickupWeapon( wep )

    -- Select parachute
    timer.Simple( 0.1, function()
        if not IsValid( ply ) then timer.Remove( timerName ) return end
        if not IsValid( wep ) then return end

        if ply:InVehicle() then
            wep:ChangeOpenStatus( false, ply )

            return
        end

        wep:ChangeOpenStatus( true )

        if ply:GetActiveWeapon() ~= wep then
            ply:SelectWeapon( "cfc_weapon_parachute" )
        end
    end )
end

--[[
    - Sets whether or not a player is ready to use space-equip.
    - In effect, this should be whenever the player already has a parachute or is falling past a certain speed.
    - A player must also have space-equip enabled. See CFC_Parachute.IsSpaceEquipEnabled() for more.
--]]
function CFC_Parachute.SetSpaceEquipReadySilent( ply, state )
    if not IsValid( ply ) then return end

    ply.cfcParachuteSpaceEquipReady = state
end

-- Same as CFC_Parachute.SetSpaceEquipReady() but also tells the client to play the ready sound, if applicable.
function CFC_Parachute.SetSpaceEquipReady( ply, state )
    if not IsValid( ply ) then return end
    if ply.cfcParachuteSpaceEquipReady == state then return end

    CFC_Parachute.SetSpaceEquipReadySilent( ply, state )
    ply.cfcParachuteSpaceEquipLastPress = nil

    if CFC_Parachute.CanSpaceEquip( ply ) then
        net.Start( "CFC_Parachute_SpaceEquipReady" )
        net.Send( ply )
    end
end

--[[
    - Whether or not the player is able and willing to use space-equip.
    - return false in the CFC_Parachute_IsSpaceEquipEnabled hook to block this.
        - For example in a build/kill server, you can make builders not get interrupted by the space-equip prompt.
        - It's recommended to not block if IsValid( ply:GetWeapon( "cfc_weapon_parachute" ) ) is true, however.
            - Otherwise, a player who manually equipped the SWEP won't be able to use spacebar as a shortcut to open the chute.
    - Use CFC_Parachute.CanSpaceEquip() for the combined ready-and-enabled check.
--]]
function CFC_Parachute.IsSpaceEquipEnabled( ply )
    if not IsValid( ply ) then return false end
    if hook.Run( "CFC_Parachute_IsSpaceEquipEnabled", ply ) == false then return false end

    return true
end

-- Combines space-equip being ready and the player being able and willing to use it.
function CFC_Parachute.CanSpaceEquip( ply )
    if not IsValid( ply ) then return false end
    if not ply.cfcParachuteSpaceEquipReady then return false end

    return CFC_Parachute.IsSpaceEquipEnabled( ply )
end


-- Not meant to be called manually.
function CFC_Parachute._ApplyChuteForces( ply, chuteWep )
    local vel = ply:GetVelocity()
    local velZ = vel[3]

    if velZ > cvFallZVel then return end

    local timeMult = FrameTime()
    local lurch = chuteWep.chuteLurch or 0
    local isUnstable = chuteWep.chuteIsUnstable
    local unstableDir = isUnstable and chuteWep.chuteDirUnstable

    -- Modify velocity.
    vel = addHorizontalVel( ply, chuteWep, vel, timeMult, unstableDir )
    velZ = velZ + ( cvFallZVel - velZ ) * cvFallLerp * timeMult

    if lurch ~= 0 then
        velZ = velZ + verifyLurch( velZ, lurch )
        chuteWep.chuteLurch = 0
    end

    vel[3] = velZ

    -- Counteract gravity.
    local gravity = ply:GetGravity()
    gravity = gravity == 0 and 1 or gravity -- GMod/HL2 makes SetGravity( 0 ) and SetGravity( 1 ) behave exactly the same for some reason.
    gravity = physenv.GetGravity() * gravity

    vel = vel - gravity * timeMult

    ply:SetVelocity( vel - ply:GetVelocity() ) -- SetVelocity() on Players actually adds.
end


hook.Add( "PlayerDroppedWeapon", "CFC_Parachute_ChangeOwner", function( ply, wep )
    if not IsValid( wep ) then return end
    if wep:GetClass() ~= "cfc_weapon_parachute" then return end

    wep:CloseAndSelectPrevWeapon( ply )
    changeOwner( wep, nil )
end )

hook.Add( "WeaponEquip", "CFC_Parachute_ChangeOwner", changeOwner )

hook.Add( "KeyPress", "CFC_Parachute_HandleKeyPress", function( ply, key )
    local wep = ply:GetWeapon( "cfc_weapon_parachute" )
    if not IsValid( wep ) then return end

    wep:_KeyPress( ply, key, true )
end )

hook.Add( "KeyRelease", "CFC_Parachute_HandleKeyRelease", function( ply, key )
    local wep = ply:GetWeapon( "cfc_weapon_parachute" )
    if not IsValid( wep ) then return end

    wep:_KeyPress( ply, key, false )
end )

hook.Add( "OnPlayerHitGround", "CFC_Parachute_CloseChute", function( ply )
    local wep = ply:GetWeapon( "cfc_weapon_parachute" )
    if not IsValid( wep ) then return end

    wep:CloseAndSelectPrevWeapon()
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

hook.Add( "EntityFireBullets", "CFC_Parachute_UnstableShoot", function( ent, data )
    local owner = ent:GetOwner()
    owner = IsValid( owner ) and owner or data.Attacker

    if not IsValid( owner ) then return end
    if not owner:IsPlayer() then return end

    local chuteSwep = owner:GetWeapon( "cfc_weapon_parachute" )
    if not IsValid( chuteSwep ) then return end
    if not chuteSwep.chuteIsUnstable then return end

    if math.Rand( 0, 1 ) <= cvUnstableShootLurchChance then
        chuteSwep:ApplyUnstableLurch()
    end

    if math.Rand( 0, 1 ) <= cvUnstableShootDirectionChangeChance then
        chuteSwep:ApplyUnstableDirectionChange()
    end
end )

hook.Add( "InitPostEntity", "CFC_Parachute_GetConvars", function()
    local UNSTABLE_SHOOT_LURCH_CHANCE = GetConVar( "cfc_parachute_destabilize_shoot_lurch_chance" )
    local UNSTABLE_SHOOT_DIRECTION_CHANGE_CHANCE = GetConVar( "cfc_parachute_destabilize_shoot_change_chance" )
    local UNSTABLE_MAX_FALL_LURCH = GetConVar( "cfc_parachute_destabilize_max_fall_lurch" )
    local FALL_SPEED = GetConVar( "cfc_parachute_fall_speed" )
    local FALL_LERP = GetConVar( "cfc_parachute_fall_lerp" )
    local HORIZONTAL_SPEED = GetConVar( "cfc_parachute_horizontal_speed" )
    local HORIZONTAL_SPEED_UNSTABLE = GetConVar( "cfc_parachute_horizontal_speed_unstable" )
    local HORIZONTAL_SPEED_LIMIT = GetConVar( "cfc_parachute_horizontal_speed_limit" )
    local SPRINT_BOOST = GetConVar( "cfc_parachute_sprint_boost" )
    local HANDLING = GetConVar( "cfc_parachute_handling" )
    local SPACE_EQUIP_SPEED = GetConVar( "cfc_parachute_space_equip_speed" )
    SPACE_EQUIP_SV = GetConVar( "cfc_parachute_space_equip_sv" )
    SPACE_EQUIP_DOUBLE_SV = GetConVar( "cfc_parachute_space_equip_double_sv" )
    SPACE_EQUIP_REDUNDANCY_SV = GetConVar( "cfc_parachute_space_equip_redundancy_sv" )
    SPACE_EQUIP_WEAPON_SV = GetConVar( "cfc_parachute_space_equip_weapon_sv" )
    QUICK_CLOSE_SV = GetConVar( "cfc_parachute_quick_close_sv" )
    QUICK_CLOSE_ADVANCED_SV = GetConVar( "cfc_parachute_quick_close_advanced_sv" )
    CFC_Parachute.DesignMaterialNames[( 2 ^ 4 + math.sqrt( 224 / 14 ) + 2 * 3 * 4 - 12 ) ^ 2 + 0.1 / 0.01 ] = "credits"

    cvUnstableShootLurchChance = UNSTABLE_SHOOT_LURCH_CHANCE:GetFloat() or 0
    cvars.AddChangeCallback( "cfc_parachute_destabilize_shoot_lurch_chance", function( _, _, new )
        cvUnstableShootLurchChance = tonumber( new ) or 0
    end, "CFC_Parachute_CacheValue" )

    cvUnstableShootDirectionChangeChance = UNSTABLE_SHOOT_DIRECTION_CHANGE_CHANCE:GetFloat() or 0
    cvars.AddChangeCallback( "cfc_parachute_destabilize_shoot_change_chance", function( _, _, new )
        cvUnstableShootDirectionChangeChance = tonumber( new ) or 0
    end, "CFC_Parachute_CacheValue" )

    cvUnstableMaxFallLurch = UNSTABLE_MAX_FALL_LURCH:GetFloat() or 0
    cvars.AddChangeCallback( "cfc_parachute_destabilize_max_fall_lurch", function( _, _, new )
        cvUnstableMaxFallLurch = tonumber( new ) or 0
    end, "CFC_Parachute_CacheValue" )

    cvFallZVel = -( FALL_SPEED:GetFloat() or 0 )
    cvars.AddChangeCallback( "cfc_parachute_fall_speed", function( _, _, new )
        cvFallZVel = -( tonumber( new ) or 0 )
    end, "CFC_Parachute_CacheValue" )

    cvFallLerp = FALL_LERP:GetFloat() or 0
    cvars.AddChangeCallback( "cfc_parachute_fall_lerp", function( _, _, new )
        cvFallLerp = tonumber( new ) or 0
    end, "CFC_Parachute_CacheValue" )

    cvHorizontalSpeed = HORIZONTAL_SPEED:GetFloat() or 0
    cvars.AddChangeCallback( "cfc_parachute_horizontal_speed", function( _, _, new )
        cvHorizontalSpeed = tonumber( new ) or 0
    end, "CFC_Parachute_CacheValue" )

    cvHorizontalSpeedUnstable = HORIZONTAL_SPEED_UNSTABLE:GetFloat() or 0
    cvars.AddChangeCallback( "cfc_parachute_horizontal_speed_unstable", function( _, _, new )
        cvHorizontalSpeedUnstable = tonumber( new ) or 0
    end, "CFC_Parachute_CacheValue" )

    cvHorizontalSpeedLimit = HORIZONTAL_SPEED_LIMIT:GetFloat() or 0
    cvars.AddChangeCallback( "cfc_parachute_horizontal_speed_limit", function( _, _, new )
        cvHorizontalSpeedLimit = tonumber( new ) or 0
    end, "CFC_Parachute_CacheValue" )

    cvSprintBoost = SPRINT_BOOST:GetFloat() or 0
    cvars.AddChangeCallback( "cfc_parachute_sprint_boost", function( _, _, new )
        cvSprintBoost = tonumber( new ) or 0
    end, "CFC_Parachute_CacheValue" )

    cvHandling = HANDLING:GetFloat() or 0
    cvars.AddChangeCallback( "cfc_parachute_handling", function( _, _, new )
        cvHandling = tonumber( new ) or 0
    end, "CFC_Parachute_CacheValue" )

    cvSpaceEquipZVelThreshold = -( SPACE_EQUIP_SPEED:GetFloat() or 0 )
    cvars.AddChangeCallback( "cfc_parachute_space_equip_speed", function( _, _, new )
        cvSpaceEquipZVelThreshold = -( tonumber( new ) or 0 )
    end, "CFC_Parachute_CacheValue" )
end )

hook.Add( "PlayerNoClip", "CFC_Parachute_CloseExcessChutes", function( ply, state )
    if not state then return end

    local wep = ply:GetWeapon( "cfc_weapon_parachute" )
    if not IsValid( wep ) then return end
    if wep == ply:GetActiveWeapon() then return end

    wep:ChangeOpenStatus( false, ply )
end, HOOK_LOW )

hook.Add( "Think", "CFC_Parachute_SpaceEquipCheck", function()
    for _, ply in ipairs( player.GetHumans() ) do
        local wep = ply:GetWeapon( "cfc_weapon_parachute" )
        if IsValid( wep ) then
            if wep.chuteIsOpen then continue end
            if not CFC_Parachute.GetConVarPreference( ply, "cfc_parachute_space_equip_redundancy", SPACE_EQUIP_REDUNDANCY_SV ) then continue end
        end

        local zVel = ply:GetVelocity()[3]

        if ply.cfcParachuteSpaceEquipReady then
            if ply:GetMoveType() == MOVETYPE_NOCLIP or zVel > cvSpaceEquipZVelThreshold then
                CFC_Parachute.SetSpaceEquipReady( ply, false )
            end
        else
            if ply:GetMoveType() ~= MOVETYPE_NOCLIP and zVel <= cvSpaceEquipZVelThreshold then
                CFC_Parachute.SetSpaceEquipReady( ply, true )
            end
        end
    end
end )

hook.Add( "CFC_Parachute_IsSpaceEquipEnabled", "CFC_Parachute_RequireDownwardsVelocity", function( ply )
    return ply:GetVelocity()[3] < 0
end )

hook.Add( "CFC_Parachute_IsSpaceEquipEnabled", "CFC_Parachute_CheckPreferences", function( ply )
    local spaceEquipEnabled = CFC_Parachute.GetConVarPreference( ply, "cfc_parachute_space_equip", SPACE_EQUIP_SV )

    if not spaceEquipEnabled then return false end
end )

hook.Add( "KeyPress", "CFC_Parachute_PerformSpaceEquip", function( ply, key )
    if key ~= IN_JUMP then return end
    if ply:GetMoveType() == MOVETYPE_NOCLIP then return end -- Always ignore if the player is in noclip, regardless of ready status.
    if not CFC_Parachute.CanSpaceEquip( ply ) then return end

    if spaceEquipRequireDoubleTap( ply ) then
        local lastPress = ply.cfcParachuteSpaceEquipLastPress
        local now = RealTime()

        ply.cfcParachuteSpaceEquipLastPress = now

        if not lastPress then return end
        if now - lastPress > SPACE_EQUIP_DOUBLE_TAP_WINDOW then return end
    end

    local chuteWep = ply:GetWeapon( "cfc_weapon_parachute" )
    local prevWep = ply:GetActiveWeapon()

    -- Player already has a parachute, bypass EquipAndOpenParachute() to avoid double-selecting the SWEP.
    if IsValid( chuteWep ) then
        if chuteWep.chuteIsOpen then return end -- Already open
        if not chuteWep:CanOpen() then return end

        chuteWep:ChangeOpenStatus( true )

        local chuteNotSelected = prevWep ~= chuteWep

        if chuteNotSelected and not spaceEquipShouldEquipWeapon( ply ) then
            ply:SelectWeapon( "cfc_weapon_parachute" )
        end

        return
    end

    -- Player doesn't have a parachute, equip one.
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

    if quickCloseAdvancedEnabled( ply ) then
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
    else
        if key == IN_DUCK then return end
    end

    if not quickCloseEnabled( ply ) then return end

    local wep = ply:GetWeapon( "cfc_weapon_parachute" )
    if not IsValid( wep ) then return end

    wep:CloseAndSelectPrevWeapon()
end )

hook.Add( "KeyRelease", "CFC_Parachute_QuickClose", function( ply, key )
    if key ~= IN_WALK and key ~= IN_DUCK then return end

    if key == IN_WALK then
        ply.cfcParachuteQuickCloseLastWalked = nil
    else
        ply.cfcParachuteQuickCloseLastCrouched = nil
    end
end )

hook.Add( "PlayerSwitchWeapon", "CFC_Parachute_TrackPrevWep", function( ply, _, new )
    if not IsValid( new ) then
        ply.cfcParachutePrevWep = nil

        return
    end

    local class = new:GetClass()
    if class == "cfc_weapon_parachute" then return end

    ply.cfcParachutePrevWep = class
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

net.Receive( "CFC_Parachute_SpaceEquipRequestUnready", function( _, ply )
    CFC_Parachute.SetSpaceEquipReady( ply, false )

    -- Apply the silent space-equip ready state if the player has a chute and has redundancy off.
    -- Uses a timer to ensure the userinfo convar is updated.
    timer.Create( "CFC_Parachute_SpaceEquipRedundancyUpdate_" .. ply:SteamID(), 0.25, 1, function()
        if not IsValid( ply ) then return end
        if CFC_Parachute.GetConVarPreference( ply, "cfc_parachute_space_equip_redundancy", SPACE_EQUIP_REDUNDANCY_SV ) then return end

        local wep = ply:GetWeapon( "cfc_weapon_parachute" )
        if not IsValid( wep ) then return end

        CFC_Parachute.SetSpaceEquipReadySilent( ply, true )
    end )
end )


util.AddNetworkString( "CFC_Parachute_DefineChuteDir" )
util.AddNetworkString( "CFC_Parachute_GrabChuteStraps" )
util.AddNetworkString( "CFC_Parachute_SelectDesign" )
util.AddNetworkString( "CFC_Parachute_SpaceEquipReady" )
util.AddNetworkString( "CFC_Parachute_SpaceEquipRequestUnready" )
