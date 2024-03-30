AddCSLuaFile()

SWEP.Base = "weapon_base"

SWEP.m_WeaponDeploySpeed = 1

SWEP.DrawWeaponInfoBox = false

SWEP.ViewModelFOV = 54

SWEP.CFCSimpleWeapon = true

SWEP.HoldType = "melee"

SWEP.Primary.Ammo = ""
SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = 0
SWEP.Primary.Automatic = false

SWEP.Primary.ChargeTime = 1
SWEP.Primary.AutoSwing = true

SWEP.Primary.Light = {
    Damage = 1,
    DamageType = DMG_CLUB,

    Range = 75,
    Delay = 0.1,

    Act = ACT_VM_HITCENTER,

    Sound = ""
}

SWEP.Primary.Heavy = {
    Damage = 1,
    DamageType = DMG_CLUB,

    Range = 75,
    Delay = 0.1,

    Act = ACT_VM_HITCENTER,

    Sound = ""
}

SWEP.Secondary.Ammo = ""
SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = 0
SWEP.Secondary.Automatic = false

SWEP.ChargeOffset = {
    Pos = Vector(),
    Ang = Angle()
}

include( "sh_animations.lua" )
include( "sh_attack.lua" )

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

    self:AddNetworkVar( "Float", "NextIdle" )
    self:AddNetworkVar( "Float", "ChargeTime" )
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

function SWEP:Deploy()
    self:SetHoldType( self.HoldType )
    self:SendTranslatedWeaponAnim( ACT_VM_DRAW )
    self:SetNextIdle( CurTime() + self:SequenceDuration() )

    return true
end

function SWEP:Holster()
    self:SetChargeTime( 0 )

    return true
end

function SWEP:PrimaryAttack()
    if self.Primary.ChargeTime == 0 then
        self.Primary.Automatic = self.Primary.AutoSwing
        self:LightAttack()

        return
    end

    if self:GetChargeTime() ~= 0 then
        return
    end

    self:SetChargeTime( CurTime() )

    self.Primary.Automatic = false
end

function SWEP:SecondaryAttack()

end

function SWEP:HandleIdle()
    local idle = self:GetNextIdle()

    if idle > 0 and idle <= CurTime() then
        self:SendTranslatedWeaponAnim( ACT_VM_IDLE )

        self:SetNextIdle( 0 )
    end
end

function SWEP:Think()
    self:HandleIdle()
    self:HandleCharge()
end

function SWEP:OnReloaded()
    self:SetWeaponHoldType( self:GetHoldType() )
end

function SWEP:OnRestore()
    self:SetNextIdle( CurTime() )
end
