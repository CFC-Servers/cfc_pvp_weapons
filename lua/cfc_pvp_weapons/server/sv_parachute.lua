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

    local mult = math.max( -dot * HANDLING:GetFloat(), 1 )

    return moveDir * mult
end

local function getHorizontalMoveSpeed( ply, isUnstable )
    if isUnstable then return HORIZONTAL_SPEED_UNSTABLE:GetFloat() end

    local hSpeed = HORIZONTAL_SPEED:GetFloat()

    if ply:KeyDown( IN_SPEED ) then
        return hSpeed * SPRINT_BOOST:GetFloat()
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

    return vel
end

-- Enforces lurch limits according to convars.
local function verifyLurch( velZ, lurch )
    if lurch >= 0 then return lurch end
    if math.abs( velZ ) >= UNSTABLE_MAX_FALL_LURCH:GetFloat() then return 0 end

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
    timer.Simple( 0.05, function()
        if not IsValid( ply ) then return end
        if ply:GetActiveWeapon() == wep then return end

        ply:SelectWeapon( "cfc_weapon_parachute" )

        if ply:InVehicle() then
            wep:ChangeOpenStatus( false, ply )

            return
        end

        wep:ChangeOpenStatus( true )
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
    local targetFallVelZ = -FALL_SPEED:GetFloat()
    local vel = ply:GetVelocity()
    local velZ = vel[3]

    if velZ > targetFallVelZ then return end

    local timeMult = FrameTime()
    local lurch = chuteWep.chuteLurch or 0
    local isUnstable = chuteWep.chuteIsUnstable
    local unstableDir = isUnstable and chuteWep.chuteDirUnstable

    -- Modify velocity.
    vel = addHorizontalVel( ply, chuteWep, vel, timeMult, unstableDir )
    velZ = velZ + ( targetFallVelZ - velZ ) * FALL_LERP:GetFloat() * timeMult

    if lurch ~= 0 then
        velZ = velZ + verifyLurch( velZ, lurch )
        chuteWep.chuteLurch = 0
    end

    vel[3] = velZ

    -- Counteract gravity.
    local gravity = physenv.GetGravity() * ply:GetGravity()
    vel = vel - gravity * timeMult

    ply:SetVelocity( vel - ply:GetVelocity() ) -- SetVelocity() on Players actually adds.
end


hook.Add( "PlayerDroppedWeapon", "CFC_Parachute_ChangeOwner", function( ply, wep )
    if not IsValid( wep ) then return end
    if wep:GetClass() ~= "cfc_weapon_parachute" then return end

    wep:CloseAndSelectPrevWeapon( ply )
    changeOwner( wep, ply )
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


util.AddNetworkString( "CFC_Parachute_DefineChuteDir" )
util.AddNetworkString( "CFC_Parachute_GrabChuteStraps" )
util.AddNetworkString( "CFC_Parachute_DefineDesigns" )
util.AddNetworkString( "CFC_Parachute_SelectDesign" )
util.AddNetworkString( "CFC_Parachute_SpaceEquipReady" )
