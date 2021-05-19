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
SWEP.DrawAmmo = true
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
SWEP.Primary.DefaultClip = 1
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "cfc_taser_ammo"

-- Secondary
SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = true
SWEP.Secondary.Ammo = ""

-- Convars
CreateConVar( "cfc_taser_range", 300, { FCVAR_REPLICATED, FCVAR_ARCHIVE }, "The range of the taser.", 1 )
CreateConVar( "cfc_taser_duration", 5, { FCVAR_REPLICATED, FCVAR_ARCHIVE }, "The duration of being ragdolled after tased in seconds.", 0 )
CreateConVar( "cfc_taser_string_duration", 3, { FCVAR_REPLICATED, FCVAR_ARCHIVE }, "The duration of the strings appearing after firing the taser in seconds.", 0 )
CreateConVar( "cfc_taser_cooldown", 1, { FCVAR_REPLICATED, FCVAR_ARCHIVE }, "The cooldown of the taser fire (fire rate) in seconds.", 0 )


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
    if not IsValid( ply ) then return end
    ply:SetParent()
    ply:UnSpectate()
    ply:Spawn()
    restorePlayer( ply )

    -- Player untase sound
    ragdoll:EmitSound( "common/wpn_select.wav", 100, 100, 1, CHAN_WEAPON )

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

    timer.Create( "cfc_taser_unragdoll" .. ragdoll:EntIndex(), GetConVar( "cfc_taser_duration" ):GetInt(), 1, function()
        untasePlayer( ply, ragdoll )
    end)
    return ragdoll
end

local function untaseNPC( npcTable, ragdoll )
    if not IsValid( ragdoll ) then return end
    local npc = ents.Create( npcTable.class )
    if not IsValid( npc ) then return end

    npc:SetPos( ragdoll:GetPos() )
    npc:SetHealth( npcTable.health )
    npc:SetModel( npcTable.model )
    if npcTable.weapon then
        npc:Give( npcTable.weapon )
    end
    npc:Spawn()

    ragdoll:Remove()
end

local function taseNPC( npc )
    local npcTable = {}
    if npc:GetActiveWeapon() ~= NULL then
        npcTable.weapon = npc:GetActiveWeapon():GetClass()
    end
    npcTable.class = npc:GetClass()
    npcTable.health = npc:Health()
    npcTable.model = npc:GetModel()

    local ragdoll = ents.Create( "prop_ragdoll" )
    if not IsValid( ragdoll ) then return end

    ragdoll:SetModel( npc:GetModel() )
    ragdoll:SetPos( npc:GetPos() )
    ragdoll:SetAngles( npc:GetAngles() )
    ragdoll:SetVelocity( npc:GetVelocity() )
    ragdoll:Spawn()

    npc:Remove()

    local boneCount = ragdoll:GetPhysicsObjectCount() - 1
    local velocity = npc:GetVelocity()

    for i = 0, boneCount do
        local bonePhys = ragdoll:GetPhysicsObjectNum( i )
        if IsValid( bonePhys ) then
            local boneVec, boneAng = npc:GetBonePosition( ragdoll:TranslatePhysBoneToBone( i ) )
            if boneVec and boneAng then
                bonePhys:SetPos( boneVec )
                bonePhys:SetAngles( boneAng )
            end
            bonePhys:SetVelocity( velocity )
        end
    end

    timer.Create( "cfc_taser_unragdoll" .. ragdoll:EntIndex(), GetConVar( "cfc_taser_duration" ):GetInt(), 1, function()
        untaseNPC( npcTable, ragdoll )
    end)
    return ragdoll
end

function SWEP:Reload()
    if self:Clip1() == 0 then
        self:SendWeaponAnim( ACT_VM_RELOAD )
        -- Reload sound?
        if CLIENT then
            timer.Simple( 0.48, function()
                self:GetOwner():EmitSound( "weapons/stunstick/spark3.wav", 100, 100, 1, CHAN_WEAPON )
            end)
        end
        self:SetClip1( 1 )
    end
end

function SWEP:PrimaryAttack()
    if not self:CanPrimaryAttack() then
        -- Not ready to shoot sound
        self:GetOwner():EmitSound( "common/wpn_denyselect.wav", 100, 100, 1, CHAN_WEAPON )
        return
    end

    -- Fire sound
    self:TakePrimaryAmmo( 1 )
    self:Reload()
    if CLIENT then
        self:GetOwner():EmitSound( "npc/sniper/echo1.wav", 100, 140, 1, CHAN_WEAPON )
    end

    local taserCooldown = GetConVar( "cfc_taser_cooldown" ):GetFloat()
    self:SetNextPrimaryFire( CurTime() + taserCooldown )

    local ply = self:GetOwner()
    local eyeTrace = ply:GetEyeTrace()
    local distance = eyeTrace.HitPos:Distance( ply:GetPos() )

    if CLIENT then
        timer.Create("cfc_taser_ready_sound" .. self:EntIndex(), taserCooldown, 1, function()
            -- Weapon ready sound
            self:GetOwner():EmitSound( "weapons/ar2/ar2_reload_push.wav", 100, 100, 1, CHAN_WEAPON )
        end)

        local effectdata = EffectData()
        effectdata:SetOrigin( self:GetPos() )
        effectdata:SetMagnitude( 2 )
        effectdata:SetScale( 1 )
        effectdata:SetRadius( 2 )
        util.Effect( "Sparks", effectdata )
    end

    local range = GetConVar( "cfc_taser_range" ):GetInt()
    local spawnPos
    local shouldTase

    if distance > range then
        spawnPos = ply:GetShootPos() + ( ply:EyeAngles():Forward() * range )
        shouldTase = false

        local effectdata = EffectData()
        effectdata:SetOrigin( spawnPos )
        effectdata:SetMagnitude( 2 )
        effectdata:SetScale( 1 )
        effectdata:SetRadius( 2 )
        util.Effect( "Sparks", effectdata )
    else
        spawnPos = eyeTrace.HitPos
        shouldTase = true

        local effectdata = EffectData()
        effectdata:SetOrigin( spawnPos )
        effectdata:SetMagnitude( 3 )
        effectdata:SetScale( 1 )
        effectdata:SetRadius( 3 )

        util.Effect( "Sparks", effectdata )
    end

    if CLIENT then return end

    local tazerBeamEnt = ents.Create( "prop_physics" )
    tazerBeamEnt:SetModel( "models/props_junk/garbage_newspaper001a.mdl" )
    tazerBeamEnt:SetNoDraw( true )
    tazerBeamEnt:SetCollisionGroup( COLLISION_GROUP_WORLD )
    tazerBeamEnt:SetPos( spawnPos + ply:EyeAngles():Forward() * 5 )
    tazerBeamEnt:SetSolid( SOLID_NONE )
    tazerBeamEnt:Spawn()

    local tazerBeamEnt2 = ents.Create( "prop_physics" )
    tazerBeamEnt2:SetModel( "models/props_junk/garbage_newspaper001a.mdl" )
    tazerBeamEnt2:SetNoDraw( true )
    tazerBeamEnt2:SetCollisionGroup( COLLISION_GROUP_WORLD )
    tazerBeamEnt2:SetPos( ply:EyePos() )
    tazerBeamEnt2:SetSolid( SOLID_NONE )
    tazerBeamEnt2:Spawn()

    constraint.Rope( tazerBeamEnt2, tazerBeamEnt, 0, 0, Vector( 0, 0, 0 ), Vector( 0, 1, 0 ), 0, 5000, 0, 1.5, "cable/blue_elec", false )
    constraint.Rope( tazerBeamEnt2, tazerBeamEnt, 0, 0, Vector( 0, 0, 0 ), Vector( 0, -1, 0 ), 0, 5000, 0, 1.5, "cable/blue_elec", false )

    timer.Simple( GetConVar( "cfc_taser_string_duration" ):GetInt(), function()
        if not IsValid( tazerBeamEnt ) then return end
        tazerBeamEnt:Remove()
    end)

    if not shouldTase then return end

    local isPlayer = eyeTrace.Entity:IsPlayer()
    local isNpc = eyeTrace.Entity:IsNPC()

    if isPlayer or isNpc then
        local ragdoll
        if isPlayer then
            ragdoll = tasePlayer( eyeTrace.Entity )
        end
        if isNpc then
            ragdoll = taseNPC( eyeTrace.Entity )
        end
        -- Player tase sound
        ragdoll:EmitSound( "npc/roller/mine/rmine_shockvehicle2.wav", 100, 100, 1, CHAN_WEAPON )
        tazerBeamEnt:SetParent( ragdoll )
    end
end

function SWEP:SecondaryAttack()
    return
end