AddCSLuaFile()

DEFINE_BASECLASS( "cfc_simple_base_throwing" )

SWEP.Base = "cfc_simple_base_throwing"
SWEP.PrintName = "Charged Throwable Base"
SWEP.Category = "CFC"

SWEP.Slot = 4
SWEP.Spawnable = false

SWEP.UseHands = true
SWEP.ViewModelFOV = 54
SWEP.ViewModel = Model( "models/weapons/cstrike/c_eq_fraggrenade.mdl" )
SWEP.WorldModel = Model( "models/weapons/w_eq_fraggrenade.mdl" )

SWEP.HoldType = "melee"

SWEP.Primary = {
    Ammo = "",

    ThrowAct = { ACT_VM_PULLBACK_HIGH, ACT_VM_THROW },
    LobAct = { ACT_VM_PULLBACK_LOW, ACT_VM_HAULBACK },
    RollAct = { ACT_VM_PULLBACK_LOW, ACT_VM_SECONDARYATTACK },

    -- Charge settings. Use :GetCharge() during :CreateEntity() to get the charge level.
    ChargeGap = 0.15, -- The gap between charge steps.
    ChargeStep = 1, -- Amount of charge to add per step. Must be an integer.
    ChargeMax = 5, -- Maximum charge.

    ChargeSound = "npc/combine_gunship/engine_rotor_loop1.wav", -- Should be a looping sound
    ChargeVolume = 1,
    ChargeStepSound = "",
    ChargeStepVolume = 1,
    ChargeStepPitchMinStart = 100,
    ChargeStepPitchMaxStart = 100,
    ChargeStepPitchMinEnd = 255,
    ChargeStepPitchMaxEnd = 255,
    ChargeStepPitchEase = function( x ) return x end, -- Use an easing function (e.g. math.ease.InCubic). Default is linear, which isn't in the ease library.
}


function SWEP:SetupDataTables()
    BaseClass.SetupDataTables( self )

    self:AddNetworkVar( "Int", "Charge" )
    self:AddNetworkVar( "Float", "ChargeNextTime" )
end

function SWEP:Initialize()
    self:SetCharge( 0 )
end

function SWEP:Think()
    local throw = self:GetFinishThrow()
    local now = CurTime()

    if throw > 0 and throw <= now then
        local charge = self:GetCharge()

        if charge == 0 then
            self:StartCharging()
        elseif self:GetChargeNextTime() <= now then
            local maxCharge = self.Primary.ChargeMax

            if charge < maxCharge then
                charge = math.min( charge + self.Primary.ChargeStep, maxCharge )

                self:SetCharge( charge )
                self:SetChargeNextTime( now + self.Primary.ChargeGap )
                self:DoChargeStepSound( charge )
                self:OnChargeStep( charge )
            end
        end
    end

    BaseClass.Think( self )
end

function SWEP:StartCharging()
    self:SetCharge( 1 )
    self:SetChargeNextTime( CurTime() + self.Primary.ChargeGap )
    self:DoChargeStepSound( 1 )

    if SERVER then
        local rf = RecipientFilter()
        rf:AddAllPlayers()

        local chargeSound = CreateSound( self, self.Primary.ChargeSound, rf )
        self._chargeSound = chargeSound
        chargeSound:Play()
        chargeSound:ChangePitch( 100 )
        chargeSound:ChangePitch( 255, self.Primary.ChargeMax * math.min( self.Primary.ChargeStep / self.Primary.ChargeGap, 1 ) )
        chargeSound:ChangeVolume( self.Primary.ChargeVolume )
    end

    self:OnStartCharging()
end

function SWEP:StopCharging()
    self:SetCharge( 0 )

    if SERVER then
        local chargeSound = self._chargeSound

        if chargeSound then
            chargeSound:Stop()
            self._chargeSound = nil
        end
    end

    self:OnStopCharging()
end

function SWEP:DoChargeStepSound( charge )
    local primary = self.Primary
    local chargeStepSound = primary.ChargeStepSound
    if chargeStepSound == "" then return end

    local chargeStepPitchMinStart = primary.ChargeStepPitchMinStart
    local chargeStepPitchMaxStart = primary.ChargeStepPitchMaxStart
    local chargeStepPitchMinEnd = primary.ChargeStepPitchMinEnd
    local chargeStepPitchMaxEnd = primary.ChargeStepPitchMaxEnd

    local pitchMin = chargeStepPitchMinStart
    local pitchMax = chargeStepPitchMaxStart

    if chargeStepPitchMinStart ~= chargeStepPitchMinEnd or chargeStepPitchMaxStart ~= chargeStepPitchMaxEnd then
        local frac = primary.ChargeStepPitchEase( charge / primary.ChargeMax )
        pitchMin = Lerp( frac, chargeStepPitchMinStart, chargeStepPitchMinEnd )
        pitchMax = Lerp( frac, chargeStepPitchMaxStart, chargeStepPitchMaxEnd )
    end

    local pitch = pitchMin == pitchMax and pitchMin or math.Rand( pitchMin, pitchMax )

    self:EmitSound( chargeStepSound, 75, pitch, primary.ChargeStepVolume )
end

if SERVER then
    function SWEP:ThrowEntity( mode )
        BaseClass.ThrowEntity( self, mode )
        self:StopCharging()
    end

    function SWEP:Holster()
        self:StopCharging()
        return BaseClass.Holster( self )
    end

    function SWEP:OnRemove()
        self:StopCharging()
        return BaseClass.OnRemove( self )
    end
else
    function SWEP:CustomAmmoDisplay()
        local charge = self:GetCharge()

        return {
            Draw = true,
            PrimaryClip = self:GetOwner():GetAmmoCount( self.Primary.Ammo ),
            SecondaryAmmo = charge > 0 and charge or nil,
        }
    end
end


----- OVERRIDEABLE FUNCTIONS -----

function SWEP:OnStartCharging()
end

function SWEP:OnStopCharging()
end

function SWEP:OnChargeStep( _charge )
end
