CFC_Parachute = CFC_Parachute or {}

CFC_Parachute.DesignMaterials = false
CFC_Parachute.DesignMaterialNames = false
CFC_Parachute.DesignMaterialCount = 21 -- Default value for in case someone changes their design without anyone having spawned a parachute swep yet
CFC_Parachute.DesignMaterialSub = string.len( "models/cfc/parachute/parachute_" ) + 1

local UNSTABLE_SHOOT_LURCH_CHANCE = GetConVar( "cfc_parachute_destabilize_shoot_lurch_chance" )
local UNSTABLE_SHOOT_DIRECTION_CHANGE_CHANCE = GetConVar( "cfc_parachute_destabilize_shoot_change_chance" )

local DESIGN_MATERIALS
local DESIGN_MATERIAL_NAMES
local DESIGN_MATERIAL_COUNT = CFC_Parachute.DesignMaterialCount
local DESIGN_REQUEST_BURST_LIMIT = 10
local DESIGN_REQUEST_BURST_DURATION = 3

local LFS_EXISTS
local LFS_AUTO_CHUTE_HEIGHT
local LFS_EJECT_LAUNCH_FORCE
local LFS_EJECT_LAUNCH_BIAS
local LFS_ENTER_RADIUS

local isValid = IsValid

local function changeOwner( wep, ply )
    if not isValid( wep ) then return end
    if wep:GetClass() ~= "cfc_weapon_parachute" then return end

    timer.Simple( 0, function()
        if not isValid( wep ) or not wep.ChangeOwner then return end

        wep:ChangeOwner( ply )
    end )
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

    local function onlyWorldFilter( ent )
        return ent:IsWorld()
    end

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

            local tr = util.TraceHull( {
                start = plyPos,
                endpos = plyPos + Vector( 0, 0, -minHeight ),
                mins = -hull,
                maxs = hull,
                filter = onlyWorldFilter,
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

            if plane.GetDriverSeat then -- Verify that it's not some other type of LFS entity

                if plane:GetPos():DistToSqr( plyPos ) <= radiusSqr then

                    return plane
                end
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

hook.Add( "EntityFireBullets", "CFC_Parachute_UnstableShoot", function( ent, data )
    local owner = ent:GetOwner()

    if not isValid( owner ) then
        owner = data.Attacker
    end

    if not isValid( owner ) or not owner:IsPlayer() then return end

    local chuteSwep = owner:GetWeapon( "cfc_weapon_parachute" )

    if not isValid( chuteSwep ) or not chuteSwep.chuteIsUnstable then return end

    if not UNSTABLE_SHOOT_LURCH_CHANCE or not UNSTABLE_SHOOT_DIRECTION_CHANGE_CHANCE then
        UNSTABLE_SHOOT_LURCH_CHANCE = GetConVar( "cfc_parachute_destabilize_shoot_lurch_chance" )
        UNSTABLE_SHOOT_DIRECTION_CHANGE_CHANCE = GetConVar( "cfc_parachute_destabilize_shoot_change_chance" )
    end

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
