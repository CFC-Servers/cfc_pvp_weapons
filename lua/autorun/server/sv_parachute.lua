CFC_Parachute = CFC_Parachute or {}

CFC_Parachute.AllChuteSwepsCount = CFC_Parachute.AllChuteSwepsCount or 0
CFC_Parachute.AllChuteSweps = CFC_Parachute.AllChuteSweps or {}

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

local allChuteSweps = CFC_Parachute.AllChuteSweps

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

local function changeOwner( wep, ply )
    if not IsValid( wep ) then return end
    if wep:GetClass() ~= "cfc_weapon_parachute" then return end

    timer.Simple( 0, function()
        wep:ChangeOwner( ply )
    end )
end

local function trySetupLFS()
    if not LFS_EXISTS then return end

    LFS_AUTO_CHUTE_HEIGHT = GetConVar( "cfc_parachute_lfs_auto_height" )

    local function onlyWorldFilter( ent )
        return ent:IsWorld()
    end

    hook.Add( "PlayerLeaveVehicle", "CFC_Parachute_LFSAutoChute", function( ply, vehicle )
        if not IsValid( ply ) or not ply:IsPlayer() or not ply:Alive() or not IsValid( vehicle ) then return end
        
        local lfsPlane = vehicle.LFSBaseEnt

        if not IsValid( lfsPlane ) then return end
        if hook.Run( "CFC_Parachute_CanLFSAutoChute", ply, vehicle, lfsPlane ) == false then return end

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

        timer.Simple( 0.1, function()
            if ply:GetActiveWeapon() == wep then return end

            ply:SelectWeapon( "cfc_weapon_parachute" )
        end )

        timer.Simple( 0.2, function()
            if wep.chuteIsOpen then return end

            wep:PrimaryAttack()
        end )
    end )

    hook.Add( "CFC_Parachute_CanLFSAutoChute", "CFC_Parachute_CheckAutoEquipConVar", function( ply )
        if ply:GetInfoNum( "cfc_parachute_lfs_auto_equip", 1 ) == 0 then return false end
    end )
end

hook.Add( "PlayerDroppedWeapon", "CFC_Parachute_ChangeOwner", function( ply, wep )
    changeOwner( wep, ply )
end )

hook.Add( "WeaponEquip", "CFC_Parachute_ChangeOwner", changeOwner )

hook.Add( "Think", "CFC_Parachute_ApplyChuteForces", function()
    local count = CFC_Parachute.AllChuteSwepsCount

    for i = 1, count do
        local wep = allChuteSweps[i]

        if IsValid( wep ) then
            wep:ApplyChuteForces()
        end
    end
end )

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

hook.Add( "EntityFireBullets", "CFC_Parachute_UnstableShoot", function( ent, data )
    local owner = ent:GetOwner()

    if not IsValid( owner ) then
        owner = data.Attacker
    end

    if not IsValid( owner ) then return end

    local chuteSwep = owner:GetWeapon( "cfc_weapon_parachute" )

    if not IsValid( chuteSwep ) or not chuteSwep.chuteIsUnstable then return end

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

    trySetupLFS()
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
util.AddNetworkString( "CFC_Parachute_DefineChuteUnfurlStatus" )
util.AddNetworkString( "CFC_Parachute_GrabChuteStraps" )
util.AddNetworkString( "CFC_Parachute_DefineDesigns" )
util.AddNetworkString( "CFC_Parachute_SelectDesign" )
