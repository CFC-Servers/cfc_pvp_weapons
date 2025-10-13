AddCSLuaFile()
DEFINE_BASECLASS( "cfc_simple_base" )

SWEP.Category           = "CFC"
SWEP.PrintName          = "Stinger Missile"
SWEP.Author             = "CFC"
SWEP.Instructions       = "Homing, anti-air RPG.\nFor best results, use on distant targets."
SWEP.Slot               = 4
SWEP.SlotPos            = 9

SWEP.Spawnable          = true
SWEP.AdminSpawnable     = false
SWEP.ViewModel          = "models/weapons/c_rpg.mdl"
SWEP.WorldModel         = "models/weapons/w_rocket_launcher.mdl"
SWEP.UseHands           = true
SWEP.ViewModelFlip      = false
SWEP.ViewModelFOV       = 53
SWEP.Weight             = 42
SWEP.AutoSwitchTo       = true
SWEP.AutoSwitchFrom     = true
SWEP.HoldType           = "rpg"

SWEP.Primary.ClipSize        = 1
SWEP.Primary.DefaultClip     = 1
SWEP.Primary.Automatic       = false
SWEP.Primary.Ammo1           = "RPG_Round"

SWEP.Secondary.ClipSize      = -1
SWEP.Secondary.DefaultClip   = -1
SWEP.Secondary.Automatic     = false
SWEP.Secondary.Ammo          = "none"

SWEP.ReloadSpeedMul = 0.5
SWEP.UnmodReloadTime = 1.8 -- rough estimate of unmodified reload time

if CLIENT then
    SWEP.BounceWeaponIcon = false
    SWEP.WepSelectIcon = surface.GetTextureID( "vgui/hud/cfc_stinger_launcher_wepselecticon" )
end

SWEP.CFC_FirstTimeHints = {
    {
        Message = "This is a homing, anti-air RPG",
        Sound = "ambient/water/drip1.wav",
        Duration = 8,
        DelayNext = 7,
    },
    {
        Message = "Aim at a vehicle, and FIRE when the reticle turns red!",
        Sound = "ambient/water/drip2.wav",
        Duration = 15,
        DelayNext = 0,
    },
}

function SWEP:SetupDataTables()
    self:NetworkVar( "Entity", "ClosestEnt" )
    self:NetworkVar( "Bool", "IsLocked" )
    self:NetworkVar( "Float", "LockedOnTime" )

    self:NetworkVar( "Bool", "IsReloading" )
    self:NetworkVar( "Float", "ReloadFinish" )
end

function SWEP:Initialize()
    self:SetHoldType( self.HoldType )
end

local stingerLockTimeVar = CreateConVar( "cfc_stinger_locktime", 4, { FCVAR_ARCHIVE, FCVAR_REPLICATED } )
local stingerLockAngleVar

if SERVER then -- this mess stays because cvars.AddChangeCallback doesnt work with replicated convars
    stingerLockAngleVar = CreateConVar( "cfc_stinger_lockangle", 10, FCVAR_ARCHIVE )

    local maxRangeVar = CreateConVar( "cfc_stinger_maxrange", 60000, { FCVAR_ARCHIVE } )
    local maxRange
    local function doMaxRange()
        maxRange = maxRangeVar:GetInt()
        local fogController = ents.FindByClass( "env_fog_controller" )[1]
        if IsValid( fogController ) then
            local fogRange = fogController:GetKeyValues().farz
            if fogRange > 0 then -- valid farz pls
                maxRange = math.min( maxRange, fogRange )
            end
        end

        SetGlobal2Int( "cfc_stinger_maxrange", maxRange )
    end

    cvars.AddChangeCallback( "cfc_stinger_maxrange", doMaxRange, "CFC_Stinger_Range" )
    hook.Add( "InitPostEntity", "CFC_Stinger_Range", doMaxRange )
    doMaxRange() -- autorefresh
end

function SWEP:GetPotentialTargets()
    local foundVehicles = {}
    local addedAlready = {}

    for _, vehicle in ipairs( ents.FindByClass( "npc_helicopter" ) ) do
        table.insert( foundVehicles, vehicle )
    end

    for _, vehicle in ipairs( ents.FindByClass( "npc_combinegunship" ) ) do
        table.insert( foundVehicles, vehicle )
    end

    for _, vehicle in ipairs( ents.FindByClass( "npc_combinedropship" ) ) do
        table.insert( foundVehicles, vehicle )
    end

    for _, vehicle in ipairs( ents.FindByClass( "prop_vehicle_*" ) ) do
        local vechiclesDriver = vehicle:GetDriver()
        if IsValid( vechiclesDriver ) then
            local parent = vehicle:GetParent()
            if parent:IsVehicle() and parent:GetDriver() == vehiclesDriver and not addedAlready[parent] then -- glide/simfphys
                table.insert( foundVehicles, parent )
                addedAlready[parent] = true
                addedAlready[vehicle] = true
            else
                table.insert( foundVehicles, vehicle )
            end
        end
    end

    return foundVehicles
end

function SWEP:Think()
    if self:GetIsReloading() and self:GetReloadFinish() < CurTime() then
        self:SetIsReloading( false )
    end
    if CLIENT then return end

    self.nextSortTargets = self.nextSortTargets or 0
    self.findTime = self.findTime or 0
    self.nextFind = self.nextFind or 0

    local curtime = CurTime()
    local owner = self:GetOwner()
    local findTime = self.findTime
    local lockOnTime = stingerLockTimeVar:GetFloat()

    if findTime + lockOnTime < curtime and IsValid( self:GetClosestEnt() ) then
        self.Locked = true
    else
        self.Locked = false
    end

    if self.Locked ~= self:GetIsLocked() then
        self:SetIsLocked( self.Locked )

        if self.Locked then
            self.LockSND = CreateSound( owner, "weapons/cfc_stinger/radar_lock.wav" )
            self.LockSND:PlayEx( 0.5, 100 )

            if self.TrackSND then
                self.TrackSND:Stop()
                self.TrackSND = nil
            end
        else
            if self.LockSND then
                self.LockSND:Stop()
                self.LockSND = nil
            end
        end
    end

    if self.nextFind < curtime then
        self.nextFind = curtime + 3
        self.foundVehicles = self:GetPotentialTargets()
    end

    if self:Clip1() <= 0 then
        self:SetClosestEnt( nil )
        if self.TrackSND then
            self.TrackSND:Stop()
            self.TrackSND = nil
        end
    elseif self.nextSortTargets < curtime then
        self.nextSortTargets = curtime + 0.25
        local vehicles = self.foundVehicles or {}
        self.foundVehicles = vehicles

        local eyeDir = owner:GetAimVector()
        local eyePos = owner:GetShootPos()

        local maxRange = GetGlobal2Int( "cfc_stinger_maxrange" )
        local lockAng = stingerLockAngleVar:GetFloat()

        local oldClosestEnt = self:GetClosestEnt()
        local oldDist = math.huge
        local oldAng = 180

        local newClosestEnt = NULL
        local newClosestDist = maxRange
        local newSmallestAng = lockAng

        for index, vehicle in pairs( vehicles ) do
            if vehicle == nil then continue end
            if not IsValid( vehicle ) then vehicles[index] = nil continue end

            local hookResult = hook.Run( "CFC_Stinger_BlockLockon", self, vehicle )
            if hookResult == true then vehicles[index] = nil continue end

            local vehicleCenter = vehicle:WorldSpaceCenter()
            local toVehicle = vehicleCenter - eyePos
            local dist = toVehicle:Length()

            local toVehicleNormalized = toVehicle / dist
            local ang = math.deg( math.acos( math.Clamp( eyeDir:Dot( toVehicleNormalized ), -1, 1 ) ) )

            if vehicle == oldClosestEnt then
                oldDist = dist
                oldAng = ang

            end

            if dist >= newClosestDist then continue end
            if ang >= newSmallestAng then continue end

            if not self:CanSee( vehicle, owner ) then continue end

            newClosestDist = dist
            newSmallestAng = ang
            newClosestEnt = vehicle
        end

        local newVehicleInSights = IsValid( newClosestEnt )
        local oldVehicleInSights = IsValid( oldClosestEnt ) and oldDist < maxRange and oldAng < lockAng
        local lockingOnForOneFourthOfLockOnTime = ( findTime + ( lockOnTime / 4 ) ) < curtime
        local lockingOnBlockSwitching = lockingOnForOneFourthOfLockOnTime and oldVehicleInSights and newVehicleInSights

        -- switch targets when not locking onto a target for more than 1/4th of the lockOnTime
        -- stops the rpg switching between really close targets, eg bunch of people in a simfphys, prop car, prop helicopter.
        if oldClosestEnt ~= newClosestEnt and not lockingOnBlockSwitching then
            self:SetClosestEnt( newClosestEnt )

            if IsValid( newClosestEnt ) then
                self.findTime = curtime
                self:SetLockedOnTime( curtime + lockOnTime )
                self.TrackSND = CreateSound( owner, "weapons/cfc_stinger/radar_track.wav" )
                self.TrackSND:PlayEx( 0, 100 )
                self.TrackSND:ChangeVolume( 0.5, 2 )
            elseif self.TrackSND then
                self.TrackSND:Stop()
                self.TrackSND = nil
            end
        end

        if IsValid( newClosestEnt ) and Glide then
            if newClosestEnt.IsGlideVehicle then
                -- If the target is a Glide vehicle, notify the passengers
                Glide.SendLockOnDanger( newClosestEnt:GetAllPlayers() )
            elseif newClosestEnt.GetDriver then
                -- If the target is another type of vehicle, notify the driver
                local driver = newClosestEnt:GetDriver()

                if IsValid( driver ) then
                    Glide.SendLockOnDanger( driver )
                end
            end
        end

        if not IsValid( newClosestEnt ) and self.TrackSND then
            self.TrackSND:Stop()
            self.TrackSND = nil
        end
    end
end

-- let us lock onto seats deep inside custom vehicles
function SWEP:CanSee( entity, owner )
    local pos = entity:GetPos()

    owner = owner or self:GetOwner()

    local trStruc = {
        start = owner:GetShootPos(),
        endpos = pos,
        filter = owner,
        mask = MASK_SOLID,
    }

    local trResult = util.TraceLine( trStruc )

    if trResult.HitWorld then return false end -- not behind the world tho

    return trResult.HitPos:Distance( pos ) < 500
end

function SWEP:PrimaryAttack()
    if self:GetNextPrimaryFire() > CurTime() then return end
    if self:GetIsReloading() then return end

    if not self:CanPrimaryAttack() then return end

    self:SetNextPrimaryFire( CurTime() + 0.5 )
    self:TakePrimaryAmmo( 1 )

    local owner = self:GetOwner()

    owner:ViewPunch( Angle( -10, -5, 0 ) )

    if CLIENT then return end

    local startpos = owner:GetShootPos() + owner:EyeAngles():Right() * 10
    local ent = ents.Create( "cfc_stinger_missile" )
    ent:SetPos( startpos )
    ent:SetAngles( ( owner:GetEyeTrace().HitPos - startpos ):Angle() )
    ent:SetOwner( owner )
    ent:Spawn()
    ent:Activate()

    ent:SetAttacker( owner )
    ent:SetInflictor( owner:GetActiveWeapon() )

    ent:EmitSound( "weapons/stinger_fire1.wav", 100, math.random( 80, 90 ), 1, CHAN_WEAPON )
    owner:EmitSound( "Weapon_RPG.NPC_Single" )

    util.ScreenShake( owner:GetShootPos(), 20, 20, 0.15, 800 )
    util.ScreenShake( owner:GetShootPos(), 1, 20, 3, 1500 )

    local lockOnTarget = self:GetClosestEnt()

    if IsValid( lockOnTarget ) and self:GetIsLocked() then
        ent:SetLockOn( lockOnTarget )
    end

    self:Reload()
end

function SWEP:SecondaryAttack()
    if not IsValid( self:GetClosestEnt() ) then return false end
    if not IsFirstTimePredicted() then return end

    self:SetNextSecondaryFire( CurTime() + 0.5 )

    if CLIENT then
        self:EmitSound( "buttons/lightswitch2.wav", 75, math.random( 150, 175 ), 0.25 )
    else
        self:UnLock()
    end
end

function SWEP:Deploy()
    self:SendWeaponAnim( ACT_VM_DRAW )

    return true
end

function SWEP:Reload()
    if self:GetIsReloading() then return end
    if self:Clip1() > 0 or self:GetOwner():GetAmmoCount( self.Primary.Ammo ) <= 0 then return end

    self:SetIsReloading( true )
    self:UnLock()
    self:DefaultReload( ACT_VM_RELOAD )

    local reloadSpeedMul = self.ReloadSpeedMul
    local unmodReloadTime = self.UnmodReloadTime -- match the slower anim

    local reloadTime = unmodReloadTime / reloadSpeedMul
    local nextFire = CurTime() + reloadTime
    self:SetNextPrimaryFire( nextFire )

    self:SetReloadFinish( nextFire + 0.25 )

    local owner = self:GetOwner()
    local vm = owner:GetViewModel()
    if IsValid( vm ) then
        vm:SetPlaybackRate( reloadSpeedMul ) -- slower anim
    end
end

function SWEP:UnLock()
    if self.TrackSND then
        self.TrackSND:Stop()
        self.TrackSND = nil
    end

    if self.LockSND then
        self.LockSND:Stop()
        self.LockSND = nil
    end

    self:SetClosestEnt( NULL )
    self:SetIsLocked( false )
end

function SWEP:Holster()
    self:UnLock()

    return true
end

function SWEP:OnDrop( owner )
    self:UnLock()

    return BaseClass.OnDrop( self, owner )
end

function SWEP:OnRemove()
    self:UnLock()
end

function SWEP:OwnerChanged()
    self:UnLock()
    BaseClass.OwnerChanged( self )
end

if not CLIENT then return end

local notLockedSize = 100
local lockedSize = 30
local difference = notLockedSize - lockedSize

function SWEP:DrawHUD()
    local ply = LocalPlayer()
    if ply:InVehicle() then return end

    local ent = self:GetClosestEnt()
    if not IsValid( ent ) then return end

    local pos = ent:LocalToWorld( ent:OBBCenter() )
    local scr = pos:ToScreen()
    local scrWH = ScrW() / 2
    local scrHH = ScrH() / 2

    local posX = scr.x
    local posY = scr.y

    draw.NoTexture()
    if self:GetIsLocked() then
        surface.SetDrawColor( 200, 0, 0, 255 )
    else
        surface.SetDrawColor( 200, 200, 200, 255 )
    end

    surface.DrawLine( scrWH, scrHH, posX, posY )

    local size = 0
    if self:GetIsLocked() then
        size = lockedSize
    else
        local untilLocked = self:GetLockedOnTime() - CurTime()
        local normalized = untilLocked / stingerLockTimeVar:GetFloat()
        size = math.Clamp( lockedSize + ( normalized * difference ), lockedSize, notLockedSize )
    end

    surface.DrawLine( posX - size, posY + size, posX - size * 0.5, posY + size )
    surface.DrawLine( posX + size, posY + size, posX + size * 0.5, posY + size )

    surface.DrawLine( posX - size, posY + size, posX - size, posY + size * 0.5 )
    surface.DrawLine( posX - size, posY - size, posX - size, posY - size * 0.5 )

    surface.DrawLine( posX + size, posY + size, posX + size, posY + size * 0.5 )
    surface.DrawLine( posX + size, posY - size, posX + size, posY - size * 0.5 )

    surface.DrawLine( posX - size, posY - size, posX - size * 0.5, posY - size )
    surface.DrawLine( posX + size, posY - size, posX + size * 0.5, posY - size )

    posX = posX + 1
    posY = posY + 1
    surface.SetDrawColor( 0, 0, 0, 100 )
    surface.DrawLine( posX - size, posY + size, posX - size * 0.5, posY + size )
    surface.DrawLine( posX + size, posY + size, posX + size * 0.5, posY + size )

    surface.DrawLine( posX - size, posY + size, posX - size, posY + size * 0.5 )
    surface.DrawLine( posX - size, posY - size, posX - size, posY - size * 0.5 )

    surface.DrawLine( posX + size, posY + size, posX + size, posY + size * 0.5 )
    surface.DrawLine( posX + size, posY - size, posX + size, posY - size * 0.5 )

    surface.DrawLine( posX - size, posY - size, posX - size * 0.5, posY - size )
    surface.DrawLine( posX + size, posY - size, posX + size * 0.5, posY - size )
end

