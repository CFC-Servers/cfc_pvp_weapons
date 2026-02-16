AddCSLuaFile()

SWEP.Base = "weapon_base"

SWEP.m_WeaponDeploySpeed = 1

SWEP.DrawWeaponInfoBox = false

SWEP.ViewModelTargetFOV = 54
SWEP.ViewModelFOV = 54

SWEP.CFCSimpleWeapon = true

SWEP.HoldType = "ar2"
SWEP.CustomHoldType = {}

SWEP.Firemode = -1

SWEP.Primary.Ammo = ""
SWEP.Primary.Cost = 1

SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = 0

SWEP.Primary.PumpAction = false
SWEP.Primary.PumpSound = ""

SWEP.Primary.Damage = 0
SWEP.Primary.Count = 1

SWEP.Primary.Spread = Vector( 0, 0, 0 )

SWEP.Primary.Range = 1000
SWEP.Primary.Accuracy = 12

SWEP.Primary.RangeModifier = 0.9

SWEP.Primary.Delay = 0.1

SWEP.Primary.BurstDelay = 0
SWEP.Primary.BurstEndDelay = 0

SWEP.Primary.Recoil = {
    MinAng = angle_zero,
    MaxAng = angle_zero,
    Punch = 0,
    Ratio = 0,
}

SWEP.Primary.Reload = {
    Time = 0,
    Amount = math.huge,
    Shotgun = false,
    Sound = ""
}

SWEP.Primary.Sound = ""
SWEP.Primary.TracerName = ""
SWEP.Primary.TracerFrequency = 2

SWEP.Secondary.Ammo = ""
SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = 0
SWEP.Secondary.Automatic = false

SWEP.ViewOffset = Vector()

SWEP.NPCData = {
    Burst = { 3, 5 },
    Delay = 0.1,
    Rest = { 0.5, 1 }
}

SWEP.DropCleanupDelay = 15
SWEP.DropOnDeath = false
SWEP.RetainAmmoOnDrop = false
SWEP.RetainAmmoStartingAmount = 0
SWEP.AllowMultiplePickup = true
SWEP.DoCollisionEffects = false
SWEP.DoOwnerChangedEffects = false

if CLIENT then
    include( "cl_hud.lua" )
else
    AddCSLuaFile( "cl_hud.lua" )
end

include( "sh_ammo.lua" )
include( "sh_animations.lua" )
include( "sh_attack.lua" )
include( "sh_getters.lua" )
include( "sh_helpers.lua" )
include( "sh_recoil.lua" )
include( "sh_reload.lua" )
include( "sh_sound.lua" )
include( "sh_view.lua" )

if SERVER then
    include( "sv_npc.lua" )
end

if engine.ActiveGamemode() == "terrortown" then
    include( "sh_ttt.lua" )
end

function SWEP:Initialize()
    self:SetFiremode( self.Firemode )
    self.AmmoType = self:GetAmmoType()
    self._cfcPvPWeapons_StoredAmmo = self.RetainAmmoStartingAmount
    self:SetupCollisionEffects()
end

function SWEP:SetupDataTables()
    self._NetworkVars = {
        ["String"] = 0,
        ["Bool"]   = 0,
        ["Float"]  = 0,
        ["Int"]    = 0,
        ["Vector"] = 0,
        ["Angle"]  = 0,
        ["Entity"] = 0
    }

    self:AddNetworkVar( "Entity", "LastOwner" )

    self:AddNetworkVar( "Bool", "NeedPump" )
    self:AddNetworkVar( "Bool", "FirstReload" )
    self:AddNetworkVar( "Bool", "AbortReload" )

    self:AddNetworkVar( "Int", "Firemode" )
    self:AddNetworkVar( "Int", "BurstFired" )

    self:AddNetworkVar( "Float", "NextIdle" )
    self:AddNetworkVar( "Float", "FinishReload" )

    self:AddNetworkVar( "Float", "NextFire" )
    self:AddNetworkVar( "Float", "NextAltFire" )
end

function SWEP:AddNetworkVar( varType, name, extended )
    local index = assert( self._NetworkVars[varType], "Attempt to register unknown network var type " .. varType )
    local max = varType == "String" and 3 or 31

    if index >= max then
        error( "Network var limit exceeded for " .. varType )
    end

    self:NetworkVar( varType, index, name, extended )
    self._NetworkVars[varType] = index + 1
end

function SWEP:OwnerChanged()
    local old = self:GetLastOwner()

    if IsValid( old ) and old:IsPlayer() then
        old:SetFOV( 0, 0.1, self )
    end

    local ply = self:GetOwner()

    if IsValid( ply ) and ply:IsNPC() then
        self:SetHoldType( self.HoldType )
    end

    self:SetLastOwner( ply )

    if self.DoOwnerChangedEffects and ( SERVER or ( CLIENT and IsFirstTimePredicted() ) ) then
        timer.Simple( 0, function()
            if not IsValid( self ) then return end
            if not IsValid( self:GetOwner() ) then
                self:OnDroppedFX()
            else
                self:OnPickedUpFX()
            end
        end )
    end
end

function SWEP:OnPickedUpFX() -- stub, see super cinderblock
end

function SWEP:OnDroppedFX() -- stub, see super cinderblock
end

function SWEP:Deploy()
    self:UpdateFOV( 0.1 )
    self:SetHoldType( self.HoldType )
    self:SendTranslatedWeaponAnim( ACT_VM_DRAW )
    self:SetNextIdle( CurTime() + self:SequenceDuration() )

    return true
end

function SWEP:Holster()
    self:SetFirstReload( false )
    self:SetAbortReload( false )
    self:SetFinishReload( 0 )

    local ply = self:GetOwner()

    if IsValid( ply ) and ply:IsPlayer() then
        ply:SetFOV( 0, 0.1, self )
    end

    return true
end

function SWEP:PrimaryAttack()
    if self:GetNextFire() > CurTime() or not self:CanPrimaryFire() then return end

    self:PrimaryFire()
end

function SWEP:SecondaryAttack()
    self:TryAltFire()
end

function SWEP:PrimaryRelease()
end

function SWEP:SecondaryRelease()
end

function SWEP:HandleRelease()
    local ply = self:GetOwner()
    if not IsValid( ply ) then return end

    if ply:KeyReleased( IN_ATTACK ) then
        self:PrimaryRelease()
    end

    if ply:KeyReleased( IN_ATTACK2 ) then
        self:SecondaryRelease()
    end
end

function SWEP:HandleIdle()
    local idle = self:GetNextIdle()

    if idle > 0 and idle <= CurTime() then
        self:SendTranslatedWeaponAnim( ACT_VM_IDLE )

        self:SetNextIdle( 0 )
    end
end

function SWEP:HandlePump()
    if self:GetNeedPump() and not self:IsReloading() and self:GetNextFire() <= CurTime() then
        if not self.Primary.PumpOnEmpty and self:Clip1() == 0 then
            return
        end

        self:SendTranslatedWeaponAnim( ACT_SHOTGUN_PUMP )

        local snd = self.Primary.PumpSound

        if snd ~= "" and IsFirstTimePredicted() then
            self:EmitSound( snd )
        end

        local duration = self:SequenceDuration()

        self:SetNextFire( CurTime() + duration )
        self:SetNextIdle( CurTime() + duration )

        self:SetNeedPump( false )
    end
end

function SWEP:HandleBurst()
    if self:GetBurstFired() > 0 and CurTime() > self:GetNextFire() + engine.TickInterval() then
        self:SetBurstFired( 0 )
        self:SetNextFire( CurTime() + self:GetDelay() )
    end
end

function SWEP:Think()
    self:HandleRelease()
    self:HandleReload()
    self:HandleIdle()
    self:HandlePump()
    self:HandleBurst()
    self:HandleViewModel()
end

function SWEP:OnReloaded()
    if self:GetHoldType() ~= "" then
        self:SetWeaponHoldType( self:GetHoldType() )
    end
end

function SWEP:OnRestore()
    self:SetFirstReload( false )
    self:SetAbortReload( false )

    self:SetBurstFired( 0 )

    self:SetNextIdle( CurTime() )
    self:SetFinishReload( 0 )

    self:SetNextFire( CurTime() )
    self:SetNextAltFire( CurTime() )
end

function SWEP:OnDrop( owner )
    if self.DropCleanupDelay then
        local timerName = "CFC_PvpWeapons_CleanupSelf_" .. self:GetCreationID()
        timer.Create( timerName, self.DropCleanupDelay, 1, function()
            if not IsValid( self ) then return end
            if IsValid( self:GetParent() ) then return end
            SafeRemoveEntity( self )
        end )
    end

    if self.RetainAmmoOnDrop then
        local ammoType = self.RetainAmmoOnDrop
        if ammoType == true then
            ammoType = self.Primary.Ammo
        end

        self._cfcPvPWeapons_StoredAmmo = owner:GetAmmoCount( ammoType )
        owner:SetAmmo( 0, ammoType )
    end
end

function SWEP:Equip( owner )
    self:GiveStoredAmmo( owner )
end

function SWEP:EquipAmmo( owner )
    self:GiveStoredAmmo( owner )
end

function SWEP:GiveStoredAmmo( owner )
    if not self.RetainAmmoOnDrop then return end

    local ammoType = self.RetainAmmoOnDrop
    if ammoType == true then
        ammoType = self.Primary.Ammo
    end

    owner:GiveAmmo( self._cfcPvPWeapons_StoredAmmo or 0, ammoType )
    self._cfcPvPWeapons_StoredAmmo = 0
end

function SWEP:MakeCollisionEffectFunc() -- stub, see super cinderblock
end

function SWEP:SetupCollisionEffects()
    if not SERVER then return end
    if self.DoCollisionEffects then
        self:AddCallback( "PhysicsCollide", self:MakeCollisionEffectFunc() )
    end
    if self.HasFunHeavyPhysics then
        local physObj = self:GetPhysicsObject()
        if IsValid( physObj ) then
            physObj:SetMass( 5000 )
            physObj:SetMaterial( "Rubber" )
        end
    end
end

function SWEP:MakeDropOnDeathCopy( owner )
    local wep = ents.Create( self:GetClass() )
    wep:SetPos( owner:GetShootPos() + owner:GetAimVector() * 16 )
    wep:SetAngles( owner:EyeAngles() )
    wep:Spawn()

    if self.RetainAmmoOnDrop then
        wep._cfcPvPWeapons_StoredAmmo = owner:GetAmmoCount( self.Primary.Ammo )
    end

    return wep
end

function SWEP:CanDropOnDeath()
    return true
end

function SWEP:DropOnDeathFX( _owner ) -- stub, see super cinderblock
end

function SWEP:CanPlayerPickUp( _ply )
    return true
end


hook.Add( "PlayerDeath", "CFCPvPWeapons_DropOnDeath", function( ply )
    local weps = ply:GetWeapons()
    for i = #weps, 1, -1 do
        local wep = weps[i]
        if not IsValid( wep ) then continue end
        if not wep.CFCSimpleWeapon then continue end
        if not wep.DropOnDeath then continue end
        if not wep:CanDropOnDeath() then continue end

        local newWep = wep:MakeDropOnDeathCopy( ply )
        newWep:DropOnDeathFX( ply )
    end
end )

hook.Add( "PlayerCanPickupWeapon", "cfc_stickaroundondeath_nodoublepickup", function( ply, wep )
    if not wep.CFCSimpleWeapon then return end
    if not wep:CanPlayerPickUp( ply ) then return false end
    if wep.AllowMultiplePickup ~= false then return end

    local class = wep:GetClass()

    if ply:HasWeapon( class ) then
        if ply:KeyDown( IN_USE ) and ply:GetEyeTrace().Entity == wep then -- They already have one, make em switch to it!
            ply:SelectWeapon( class )
        end

        return false
    end
end )
