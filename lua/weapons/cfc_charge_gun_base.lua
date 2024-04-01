AddCSLuaFile()

DEFINE_BASECLASS( "cfc_simple_base" )
SWEP.Base = "cfc_simple_base"

SWEP.CFCSimpleWeapon = true
SWEP.CFCSimpleWeaponCharge = true

-- UI stuff

SWEP.PrintName = "cfc_charge_gun_base"
SWEP.Category = "CFC"

SWEP.Slot = 0
SWEP.Spawnable = false

-- Appearance

SWEP.UseHands = true -- If your viewmodel includes it's own hands (v_ model instead of a c_ model), set this to false

SWEP.ViewModelTargetFOV = 65
SWEP.ViewModel = Model( "models/weapons/c_rpg.mdl" ) -- Weapon viewmodel, usually a c_ or v_ model
SWEP.WorldModel = Model( "models/weapons/w_rocket_launcher.mdl" ) -- Weapon worldmodel, almost always a w_ model

SWEP.HoldType = "rpg" -- https://wiki.facepunch.com/gmod/Hold_Types
SWEP.CustomHoldType = {} -- Allows you to override any hold type animations with your own, uses [ACT_MP_STAND_IDLE] = ACT_HL2MP_IDLE_SHOTGUN formatting

-- Weapon stats

SWEP.Firemode = 0

SWEP.Primary = {
    Ammo = "Buckshot", -- The ammo type used when reloading
    Cost = 1, -- A remnant of cfc_simple_base. Leave as 1.

    ClipSize = 15, -- The max ammount of ammo for a full charge
    DefaultClip = 1000, -- How many rounds the player gets when picking up the weapon for the first time, excess ammo will be added to the player's reserves

    Damage = 1, -- Damage per shot
    Count = 1, -- Optional: Shots fired per unit ammo

    PumpAction = false, -- Optional: Tries to pump the weapon between shots
    PumpSound = "Weapon_Shotgun.Special1", -- Optional: Sound to play when pumping

    Delay = 0.15, -- Delay between each buildup of charge, use 60 / x for RPM (Rounds per minute) values
    BurstEnabled = true, -- When releasing the charge, decides whether to burst-fire the weapon once per unit ammo, or to expend the full charge in one fire call
    BurstDelay = 0.075, -- Burst only: the delay between shots during a burst
    Cooldown = 3, -- Cooldown to apply once the charge is expended
    MovementMultWhenCharging = 1, -- Multiplier against movement speed when charging
    OverchargeDelay = false, -- Once at full charge, it takes this long before overcharge occurs. False to disable.

    Range = 750, -- The range at which the weapon can hit a plate with a diameter of <Accuracy> units
    Accuracy = 12, -- The reference value to use for the previous option, 12 = headshots, 24 = bodyshots

    RangeModifier = 0.85, -- The damage multiplier applied for every 1000 units a bullet travels, e.g. 0.85 for 2000 units = 0.85 * 0.85 = 72% of original damage

    Recoil = {
        MinAng = Angle( 1, -0.3, 0 ), -- The minimum amount of recoil punch per shot
        MaxAng = Angle( 1.2, 0.3, 0 ), -- The maximum amount of recoil punch per shot
        Punch = 0.2, -- The percentage of recoil added to the player's view angles, if set to 0 a player's view will always reset to the exact point they were aiming at
        Ratio = 0.4 -- The percentage of recoil that's translated into the viewmodel, higher values cause bullets to end up above the crosshair
    },
    RecoilCharging = {
        Mult = 0, -- If above zero, will repeatedly apply recoil while charging, with this as a strength multiplier. Scales with charge level.
        MinAng = Angle( -2, -1, 0 ),
        MaxAng = Angle( 2, 1, 0 ),
        Punch = 0.2,
        Ratio = 0.4,
    },
    RecoilChargingInterval = 0.1, -- The interval at which to apply the charging recoil

    Reload = { -- Remnant of simple_base, leave as-is
        Time = 0,
        Amount = 1,
        Shotgun = false,
        Sound = ""
    },

    Sound = "doors/vent_open3.wav", -- Firing sound
    TracerName = "", -- Tracer effect, leave blank for no tracer

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

SWEP.ViewOffset = Vector( 0, 0, 0 ) -- Optional: Applies an offset to the viewmodel's position


local setMovementMult
local tryApplyChargedMovementMult


----- OVERRIDABLE FUNCTIONS -----

function SWEP:FireWeapon( _chargeAmount )
    -- Called when the weapon is fired.
    -- chargeAmount is the number of shots to fire, equal to the current charge level.
end

function SWEP:OnChargeStep( _chargeAmount )
    -- Called for each step of the charge sequence.
    -- chargeAmount is the current charge level, starting at 1.
end

function SWEP:OnFullChargeReached( _chargeAmount )
    -- Called when the weapon reaches full charge.
    -- chargeAmount should be equivalent to self.Primary.ClipSize.
end

function SWEP:OnOvercharged()
    -- Called when the weapon is overcharged.
    -- By default, releases the charge early, firing the weapon.

    self:PrimaryRelease()
end

function SWEP:OnStartCharging()
    -- Called when the weapon starts charging.
end

function SWEP:OnStopCharging()
    -- Called when the weapon stops charging.
end

function SWEP:ChargeThink()
    -- Called every tick/frame while the weapon is charging.
end


----- INSTANCE FUNCTIONS -----

function SWEP:Initialize()
    BaseClass.Initialize( self )

    self:SetCharge( 0 )
    self:SetNextFire( 0 )

    self._charging = false
    self._releasing = false
end

function SWEP:IsCharging()
    return self._charging
end

function SWEP:IsReleasing()
    return self._releasing
end

function SWEP:Think()
    BaseClass.Think( self )

    self:CheckForPrematureCharge()

    if self:IsCharging() then
        self:ChargeThink()
        self:DoChargeRecoil()
    end
end

function SWEP:CanPrimaryAttack()
    if self:GetNextFire() > CurTime() then return false end
    if self:GetReserveAmmo() <= 0 then return false end
    --if not self:CanPrimaryFire() then return false end

    return true
end

function SWEP:PrimaryAttack()
    if not self:CanPrimaryAttack() then return end

    local clipMax = self.Primary.ClipSize
    local chargeStep = self.Primary.Delay

    local chargeStepSound = self.Primary.ChargeStepSound
    local chargeStepVolume = self.Primary.ChargeStepVolume
    local chargeStepPitchMinStart = self.Primary.ChargeStepPitchMinStart
    local chargeStepPitchMaxStart = self.Primary.ChargeStepPitchMaxStart
    local chargeStepPitchMinEnd = self.Primary.ChargeStepPitchMinEnd
    local chargeStepPitchMaxEnd = self.Primary.ChargeStepPitchMaxEnd
    local chargeStepPitchEase = self.Primary.ChargeStepPitchEase

    tryApplyChargedMovementMult( self, false )

    self._charging = true
    self:OnStartCharging()

    timer.Create( "CFC_ChargeGun_Charge_" .. self:EntIndex(), chargeStep, 0, function()
        if not self:IsValid() then return end

        local ammo = self:GetReserveAmmo()
        if ammo <= 0 then return end

        local clip = self:Clip1()

        if clip >= clipMax then
            self:OnFullChargeReached( clip )

            timer.Remove( "CFC_ChargeGun_Charge_" .. self:EntIndex() )

            local overchargeDelay = self.Primary.OverchargeDelay
            if not overchargeDelay then return end

            timer.Create( "CFC_ChargeGun_Overcharge_" .. self:EntIndex(), overchargeDelay, 1, function()
                if not self:IsValid() then return end

                self:OnOvercharged()
                self:StopCharge()

                if not self:IsReleasing() then
                    self:SetCharge( 0 )
                end
            end )

            return
        end

        clip = clip + 1

        self:SetClip1( clip )
        self:SetReserveAmmo( ammo - 1 )

        if chargeStepSound ~= "" and SERVER then
            local pitchMin = chargeStepPitchMinStart
            local pitchMax = chargeStepPitchMaxStart

            if chargeStepPitchMinStart ~= chargeStepPitchMinEnd or chargeStepPitchMaxStart ~= chargeStepPitchMaxEnd then
                local frac = chargeStepPitchEase( clip / clipMax )
                pitchMin = Lerp( frac, chargeStepPitchMinStart, chargeStepPitchMinEnd )
                pitchMax = Lerp( frac, chargeStepPitchMaxStart, chargeStepPitchMaxEnd )
            end

            local pitch = pitchMin == pitchMax and pitchMin or math.Rand( pitchMin, pitchMax )

            self:EmitSound( chargeStepSound, 75, pitch, chargeStepVolume )
        end

        self:OnChargeStep( clip )
    end )

    if CLIENT then return end

    local rf = RecipientFilter()
    rf:AddAllPlayers()

    local chargeSound = CreateSound( self, self.Primary.ChargeSound, rf )
    self._chargeSound = chargeSound
    chargeSound:Play()
    chargeSound:ChangePitch( 100 )
    chargeSound:ChangePitch( 255, clipMax * chargeStep )
    chargeSound:ChangeVolume( self.Primary.ChargeVolume )
end

function SWEP:Reload()
    -- Do nothing.
end

function SWEP:ForceStopFire()
    -- Do nothing.
end

function SWEP:PrimaryRelease()
    if not self:IsCharging() then return end

    local clip = self:Clip1()
    if clip <= 0 then return end

    self:StopCharge()
    self._releasing = true

    local cooldown = self.Primary.Cooldown

    -- No burst
    if not self.Primary.BurstEnabled then
        self:SetClip1( 0 )
        self:FireWeapon( clip )
        self:SetNextFire( CurTime() + cooldown )
        self._releasing = false

        return
    end

    -- Burst
    local burstDelay = self.Primary.BurstDelay

    self:SetNextFire( CurTime() + burstDelay * clip + cooldown )

    timer.Create( "CFC_ChargeGun_Release_" .. self:EntIndex(), burstDelay, clip, function()
        if not self:IsValid() then return end

        clip = clip - 1

        self:SetClip1( clip )
        self:FireWeapon( 1 )

        if clip <= 0 then
            self._releasing = false
        end
    end )
end

function SWEP:Deploy()
    BaseClass.Deploy( self )
    self:SetCharge( 1 )

    return true
end

function SWEP:Holster()
    BaseClass.Holster( self )
    self:SetCharge( 0 )
    self:StopCharge()

    return not self:IsReleasing()
end

function SWEP:OnRemove()
    self:SetCharge( 0 )
    self:StopCharge()
end

function SWEP:OwnerChanged()
    BaseClass.OwnerChanged( self )
    self:SetCharge( 0 )
    self:StopCharge()

    if self:IsReleasing() then
        self._releasing = false

        timer.Remove( "CFC_ChargeGun_Release_" .. self:EntIndex() )
    end
end

function SWEP:CheckForPrematureCharge()
    if self:IsCharging() then return end
    if self:IsReleasing() then return end

    local owner = self:GetOwner()
    if not IsValid( owner ) then return end

    -- Insert starting charge to indicate that the weapon is ready to charge.
    if self:Clip1() == 0 and self:CanPrimaryAttack() then
        self:SetCharge( 1 )
    end

    if owner:KeyDown( IN_ATTACK ) then
        if not self._prematureChargeOneTickCheck then -- gmod jank
            self._prematureChargeOneTickCheck = true

            return
        end

        self:PrimaryAttack()
    else
        self._prematureChargeOneTickCheck = false
    end
end

function SWEP:SetCharge( desClip )
    local clip = self:Clip1()
    if clip == desClip then return end

    local owner = self:GetOwner()

    self:SetClip1( desClip )

    if IsValid( owner ) then
        local ammoType = self.Primary.Ammo
        local curAmmo = owner:GetAmmoCount( ammoType )

        owner:SetAmmo( math.max( curAmmo + clip - desClip, 0 ), ammoType )
    end
end

function SWEP:StopCharge()
    local wasCharging = self:IsCharging()

    self._charging = false

    timer.Remove( "CFC_ChargeGun_Charge_" .. self:EntIndex() )
    timer.Remove( "CFC_ChargeGun_Overcharge_" .. self:EntIndex() )

    local chargeSound = self._chargeSound

    if chargeSound then
        chargeSound:Stop()
        self._chargeSound = nil
    end

    if wasCharging then
        tryApplyChargedMovementMult( self, true )
        self:OnStopCharging()
    end
end

function SWEP:DoChargeRecoil()
    if CLIENT then return end

    local primary = self.Primary
    local recoilCharging = primary.RecoilCharging
    local mult = recoilCharging.Mult
    if mult <= 0 then return end

    local now = CurTime()
    local nextChargeRecoil = self._nextChargeRecoil or 0

    if now >= nextChargeRecoil then
        self:ApplyRecoil( recoilCharging, mult * self:Clip1() / primary.ClipSize )
        self._nextChargeRecoil = now + primary.RecoilChargingInterval
    end
end


----- PRIVATE FUNCTIONS -----

if FindMetaTable( "Player" ).SetMoveSpeedMultiplier then
    -- Utility function from cfc_pvp_movespeed
    setMovementMult = function( ply, mult )
        ply:SetMoveSpeedMultiplier( mult )
    end
else
    local baseRunSpeed
    local baseWalkSpeed

    setMovementMult = function( ply, mult )
        if not baseRunSpeed then -- Could be more accurate, but should work well enough to cover standard Sandbox and TTT.
            baseRunSpeed = ply:GetRunSpeed()
            baseWalkSpeed = ply:GetWalkSpeed()
        end

        ply:SetRunSpeed( baseRunSpeed * mult )
        ply:SetWalkSpeed( baseWalkSpeed * mult )
    end
end

tryApplyChargedMovementMult = function( wep, reset )
    if CLIENT then return end

    local movementMult = wep.Primary.MovementMultWhenCharging
    if movementMult == 1 then return end

    local owner = wep:GetOwner()
    if not IsValid( owner ) then return end

    if reset then
        setMovementMult( owner, 1 )
    else
        setMovementMult( owner, movementMult )
    end
end


----- SETUP -----

if SERVER then
    hook.Add( "PlayerDroppedWeapon", "CFC_PvPWeapons_ChargeGunBase_ResetMovementMult", function( ply, wep )
        if not IsValid( ply ) then return end
        if not IsValid( wep ) then return end
        if not wep.CFCSimpleWeaponCharge then return end
        if wep.Primary.MovementMultWhenCharging == 1 then return end

        setMovementMult( ply, 1 )
    end )
end
