CFC_Parachute = CFC_Parachute or {}

CFC_Parachute.AllChuteSwepsCount = CFC_Parachute.AllChuteSwepsCount or 0
CFC_Parachute.AllChuteSweps = CFC_Parachute.AllChuteSweps or {}

CFC_Parachute.DesignMaterials = false
CFC_Parachute.DesignMaterialNames = false
CFC_Parachute.DesignMaterialCount = 15 -- Default value for in case someone changes their design without anyone having spawned a parachute swep yet
CFC_Parachute.DesignMaterialSub = string.len( "models/cfc/parachute/parachute_" ) + 1

local UNSTABLE_SHOOT_CHANCE = GetConVar( "cfc_parachute_destabilize_shoot_change_change" )

local DESIGN_MATERIALS
local DESIGN_MATERIAL_NAMES
local DESIGN_MATERIAL_COUNT = CFC_Parachute.DesignMaterialCount

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

    if not IsValid( chuteSwep ) or not chuteSwep.isChuteUnstable then return end
    if math.Rand( 0, 1 ) > UNSTABLE_SHOOT_CHANCE:GetFloat() then return end

    chuteSwep:ApplyUnstableDirectionChange()
end )

hook.Add( "CFC_Parachute_ChuteCreated", "CFC_Parachute_DefineDesigns", function( chute )
    local designMaterials = CFC_Parachute.DesignMaterials

    if designMaterials then return end

    designMaterials = chute:GetMaterials()
    designMaterialNames = {}

    local designMaterialCount = #designMaterials - 1
    local designMaterialSub = CFC_Parachute.DesignMaterialSub

    table.remove( designMaterials, 2 )
    --table.remove( designMaterials, designMaterialCount )

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

net.Receive( "CFC_Parachute_SelectDesign", function( _, ply )
    local oldDesign = net.ReadInt( 10 ) or 1
    local newDesign = net.ReadInt( 10 ) or 1

    CFC_Parachute.SetDesignSelection( ply, oldDesign, newDesign )
end )
