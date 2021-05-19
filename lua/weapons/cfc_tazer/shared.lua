AddCSLuaFile()

-- General info
SWEP.Author = "Redox"
SWEP.Contact = "CFC Discord"
SWEP.Purpose = "Tasing players and npcs."
SWEP.Base = "weapon_base"
SWEP.PrintName = "Taser"
SWEP.Instructions = "Left click to taser the target."
SWEP.Category = "CFC"

-- Visuals
SWEP.ViewModel = "models/weapons/c_pistol.mdl"
SWEP.WorldModel = "models/weapons/w_pistol.mdl"
SWEP.UseHands = true
SWEP.SetHoldType = "pistol"
SWEP.DrawAmmo = false
SWEP.DrawCrosshair = true

-- Functionals
SWEP.Slot = 1
SWEP.SlotPos = 1
SWEP.Spawnable = true
SWEP.AdminSpawnable = true
SWEP.AdminOnly = false

-- Ammo and such
-- Primary
SWEP.Primary.ClipSize = 1
SWEP.Primary.DefaultClip = 20
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "Pistol"

-- Secondary
SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = true
SWEP.Secondary.Ammo = ""

local function savePlayer( ply )
    local result = {}

    result.health = ply:Health()
    result.armor = ply:Armor()

    if ply:GetActiveWeapon():IsValid() then
        result.currentWeapon = ply:GetActiveWeapon():GetClass()
    end

    local weapons = ply:GetWeapons()

    for _, weapon in ipairs( weapons ) do
        result.weapondata = {}
        printname = weapon:GetClass()
        result.weapondata[ printname ] = {}
        result.weapondata[ printname ].clip1 = weapon:Clip1()
        result.weapondata[ printname ].clip2 = weapon:Clip2()
        result.weapondata[ printname ].ammo1 = ply:GetAmmoCount( weapon:GetPrimaryAmmoType() )
        result.weapondata[ printname ].ammo2 = ply:GetAmmoCount( weapon:GetSecondaryAmmoType() )
    end
    ply.cfcTaserData = result
end

local function restorePlayer( ply )
    local data = ply.cfcTaserData
    ply:SetParent()
    ply:SetHealth( data.health )
    ply:SetArmor( data.armor )

    for weaponClass, infoTable in pairs( data.weapondata ) do
        ply:Give( weaponClass )
        local weapon = ply:GetWeapon( weaponClass )
        weapon:SetClip1( infoTable.clip1 )
        weapon:SetClip2( infoTable.clip2 )
        ply:SetAmmo( infoTable.ammo1, weapon:GetPrimaryAmmoType() )
        ply:SetAmmo( infoTable.ammo2, weapon:GetSecondaryAmmoType() )
    end

    ply:SelectWeapon( data.currentWeapon )
end

local function untasePlayer( ply, ragdoll )
    ply:SetParent()
    ply:UnSpectate()
    ply:Spawn()
    restorePlayer( ply )

    if not IsValid( ragdoll ) then return end

    ply:SetPos( ragdoll:GetPos() )
    ply:SetVelocity( ragdoll:GetVelocity() )
    local yaw = ragdoll:GetAngles().yaw
    ply:SetAngles( Angle( 0, yaw, 0 ) )
    ragdoll:Remove()
end

local function tasePlayer( ply )
    savePlayer( ply )

    local ragdoll = ents.Create( "prop_ragdoll" )
    if not IsValid( ragdoll ) then return end

    ragdoll:SetModel( ply:GetModel() )
    ragdoll:SetPos( ply:GetPos() )
    ragdoll:SetAngles( ply:GetAngles() )
    ragdoll:SetVelocity( ply:GetVelocity() )
    ragdoll:Spawn()

    ply:SetParent( ragdoll )

    local boneCount = ragdoll:GetPhysicsObjectCount() - 1
    local velocity = ply:GetVelocity()

    for i = 0, boneCount do
        local bonePhys = ragdoll:GetPhysicsObjectNum( i )
        if IsValid( bonePhys ) then
            local boneVec, boneAng = ply:GetBonePosition( ragdoll:TranslatePhysBoneToBone( i ) )
            if boneVec and boneAng then
                bonePhys:SetPos( boneVec )
                bonePhys:SetAngles( boneAng )
            end
            bonePhys:SetVelocity( velocity )
        end
    end

    ply:Spectate( OBS_MODE_CHASE )
    ply:SpectateEntity( ragdoll )
    ply:StripWeapons()

    timer.Create( "cfc_taser_unragdoll" .. ragdoll:EntIndex(), 5, 1, function()
        untasePlayer( ply, ragdoll )
    end)
end

function SWEP:Reload()
    self:DefaultReload(ACT_VM_RELOAD)
end

--local  pos = ply:getShootPos() + ( ply:getEyeAngles():getForward() * 100)
function SWEP:PrimaryAttack()
    local ply = self:GetOwner()
    local eyeTrace = ply:GetEyeTrace()

    if CLIENT then return end

    local spawnPos = ply:GetShootPos() + ( ply:EyeAngles():Forward() * 300 )
    local tazerBeamEnt = ents.Create( "prop_physics" )
    tazerBeamEnt:SetModel( "models/hunter/blocks/cube025x025x025.mdl" )
    --tazerBeamEnt:SetNoDraw( true )
    tazerBeamEnt:SetCollisionGroup( COLLISION_GROUP_WORLD )
    tazerBeamEnt:SetPos( spawnPos )
    tazerBeamEnt:Spawn()

    constraint.Rope( tazerBeamEnt, ply, 0, 0, Vector( 0, 2, 0 ), Vector( 0, 0, 0 ), 0, 5000, 0, 1.5, "cable/blue_elec", false )
    constraint.Rope( tazerBeamEnt, ply, 0, 0, Vector( 0, -2, 0 ), Vector( 0, 0, 0 ), 0, 5000, 0, 1.5, "cable/blue_elec", false )

    timer.Simple( 3, function()
        if not IsValid( tazerBeamEnt ) then return end
        tazerBeamEnt:Remove()
    end)

    local isPlayer = eyeTrace.Entity:IsPlayer()
    local isNpc = eyeTrace.Entity:IsNPC()

    if isPlayer or isNpc then
        if isPlayer then
            tasePlayer( eyeTrace.Entity )
        end
        if isNpc then
            taseNpc( eyeTrace.Entity )
        end
    end
end