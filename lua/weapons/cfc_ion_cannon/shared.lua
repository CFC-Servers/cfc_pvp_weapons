AddCSLuaFile()

DEFINE_BASECLASS( "cfc_charge_gun_base" )
SWEP.Base = "cfc_charge_gun_base"

CFC_PvPWeapons = CFC_PvPWeapons or {}
CFC_PvPWeapons.PrimaryReleaseClasses = CFC_PvPWeapons.PrimaryReleaseClasses or {}
CFC_PvPWeapons.PrimaryReleaseClasses["cfc_ion_cannon"] = true

-- UI stuff

SWEP.PrintName = "Ion Cannon"
SWEP.Category = "CFC"

SWEP.Slot = 4
SWEP.Spawnable = true

-- Appearance

SWEP.UseHands = true -- If your viewmodel includes it's own hands (v_ model instead of a c_ model), set this to false

SWEP.ViewModelTargetFOV = 65
--SWEP.ViewModel = Model( "models/weapons/c_357.mdl" ) -- Weapon viewmodel, usually a c_ or v_ model
--SWEP.WorldModel = Model( "models/weapons/w_357.mdl" ) -- Weapon worldmodel, almost always a w_ model
SWEP.ViewModel = Model( "models/weapons/cfc_ion_cannon/c_gauss.mdl" ) -- Weapon viewmodel, usually a c_ or v_ model
SWEP.WorldModel = Model( "models/weapons/cfc_ion_cannon/w_gauss.mdl" ) -- Weapon worldmodel, almost always a w_ model

SWEP.HoldType = "rpg" -- https://wiki.facepunch.com/gmod/Hold_Types
SWEP.CustomHoldType = {} -- Allows you to override any hold type animations with your own, uses [ACT_MP_STAND_IDLE] = ACT_HL2MP_IDLE_SHOTGUN formatting
SWEP.WorldColorOverride = Color( 200, 255, 255, 255 ) -- MMod Gaus Cannon world model uses the hl2 tau cannon model strapped to the jeep, so need to apply color to it separately

-- Weapon stats

SWEP.Firemode = 0

SWEP.Primary = {
    Ammo = "AR2", -- The ammo type used when reloading
    Cost = 1, -- A remnant of cfc_simple_base. Leave as 1.

    ClipSize = 10, -- The max ammount of ammo for a full charge
    DefaultClip = 1000, -- How many rounds the player gets when picking up the weapon for the first time, excess ammo will be added to the player's reserves

    Damage = 90, -- Damage per bullet at max charge
    DamageExplosive = 150, -- Damage at max charge, done as one explosion at the impact point. 0 to disable.
    DamageExplosiveRadius = 250, -- Explosive radius at max charge.
    DamageEase = math.ease.InCubic, -- Easing function to use for the damage curve
    Count = 10, -- Optional: Shots fired per unit ammo

    PumpAction = false, -- Optional: Tries to pump the weapon between shots
    PumpSound = "Weapon_Shotgun.Special1", -- Optional: Sound to play when pumping

    Delay = 0.5, -- Delay between each buildup of charge, use 60 / x for RPM (Rounds per minute) values
    BurstEnabled = false, -- When releasing the charge, decides whether to burst-fire the weapon once per unit ammo, or to expend the full charge in one fire call
    BurstDelay = 0.075, -- Burst only: the delay between shots during a burst
    Cooldown = 2, -- Cooldown to apply once the charge is expended
    MovementMultWhenCharging = 0.5, -- Multiplier against movement speed when charging
    OverchargeDelay = 2, -- Once at full charge, it takes this long before overcharge occurs. False to disable.
    OverchargeExplosionDamage = 200, -- Damage dealt by the overcharge explosion
    OverchargeExplosionRadius = 200, -- Radius of the overcharge explosion

    -- Settings for shaking the viewmodel while charging
    ChargeVMShakeStrength = 3,
    ChargeVMShakeStrengthEase = function( x ) return x end, -- Easing function to use for the viewmodel shake strength (linear by default)
    ChargeVMShakeStrengthMovementBonus = 1.5 / 400, -- Multiplies the shake strength by 1 + ( the player's movespeed * this value ).
    ChargeVMShakeIntervalMinStart = 0.075,
    ChargeVMShakeIntervalMaxStart = 0.2,
    ChargeVMShakeIntervalMinEnd = 0.01,
    ChargeVMShakeIntervalMaxEnd = 0.075,
    ChargeVMShakeLerp = 1.5, -- How strongly to follow changes in the desired ViewOffset position, per second. 1 means it will reach the new position in 1 second, 2 in 0.5 seconds, etc.

    Range = 2000, -- The range at which the weapon can hit a plate with a diameter of <Accuracy> units
    Accuracy = 6, -- The reference value to use for the previous option, 12 = headshots, 24 = bodyshots

    RangeModifier = 0.85, -- The damage multiplier applied for every 1000 units a bullet travels, e.g. 0.85 for 2000 units = 0.85 * 0.85 = 72% of original damage

    Recoil = {
        MinAng = Angle( 20, -10, 0 ), -- The minimum amount of recoil punch per shot
        MaxAng = Angle( 40, 10, 0 ), -- The maximum amount of recoil punch per shot
        Punch = 0.2, -- The percentage of recoil added to the player's view angles, if set to 0 a player's view will always reset to the exact point they were aiming at
        Ratio = 0.4 -- The percentage of recoil that's translated into the viewmodel, higher values cause bullets to end up above the crosshair
    },
    RecoilCharging = {
        Mult = 0.04, -- If above zero, will repeatedly apply recoil while charging, with this as a strength multiplier. Scales with charge level.
        MinAng = Angle( -20, -10, 0 ),
        MaxAng = Angle( 20, 10, 0 ),
        Punch = 0.2,
        Ratio = 0.4,
    },
    RecoilChargingInterval = 0.1, -- The interval at which to apply the charging recoil

    Reload = { -- Remnant of cfc_simple_base, leave as-is
        Time = 0,
        Amount = 1,
        Shotgun = false,
        Sound = ""
    },

    Sound = "npc/env_headcrabcanister/launch.wav", -- Firing sound
    SoundPitchMin = 90,
    SoundPitchMax = 110,
    SoundPitchMultLowCharge = 2, -- Multiplies against the pitch when the charge is low
    TracerName = "AirboatGunHeavyTracer", -- Tracer effect, leave blank for no tracer
    TracerFrequency = 1,

    ChargeSound = "npc/combine_gunship/engine_rotor_loop1.wav",
    ChargeVolume = 1,
    ChargeStepSound = "physics/metal/metal_computer_impact_soft1.wav",
    ChargeStepVolume = 0.75,
    ChargeStepPitchMinStart = 100,
    ChargeStepPitchMaxStart = 100,
    ChargeStepPitchMinEnd = 255,
    ChargeStepPitchMaxEnd = 255,
    ChargeStepPitchEase = function( x ) return x end, -- Use an easing function (e.g. math.ease.InCubic). Default is linear, which isn't in the ease library.

    ExplosionSound = "npc/roller/mine/rmine_explode_shock1.wav",
    ExplosionVolume = 1,
    ExplosionPitch = 105,
}

SWEP.ViewOffset = Vector( 0, 0, 0 ) -- Optional: Applies an offset to the viewmodel's position


local VECTOR_ZERO = Vector( 0, 0, 0 )

local doExplosiveDamage


function SWEP:FireWeapon( chargeAmount )
    local owner = self:GetOwner()
    if not IsValid( owner ) then return end

    local primary = self.Primary
    local damageFrac = primary.DamageEase( chargeAmount / primary.ClipSize )
    local damage = math.max( 1, primary.Damage * damageFrac )

    local bullet = {
        Num = primary.Count,
        Src = owner:GetShootPos(),
        Dir = self:GetShootDir(),
        Spread = self:GetSpread(),
        TracerName = primary.TracerName,
        Tracer = primary.TracerName == "" and 0 or primary.TracerFrequency,
        Force = damage * 0.25,
        Damage = damage,
        Callback = function( _attacker, tr, dmginfo )
            dmginfo:ScaleDamage( self:GetDamageFalloff( tr.StartPos:Distance( tr.HitPos ) ) )
            dmginfo:SetDamageType( DMG_BULLET + DMG_DISSOLVE )
        end
    }

    owner:FireBullets( bullet )

    if SERVER then
        local damageExplosive = math.floor( primary.DamageExplosive * damageFrac )

        if damageExplosive > 0 then
            doExplosiveDamage( self, owner, damageExplosive, primary.DamageExplosiveRadius * damageFrac, damageFrac )
        end
    end

    self:ApplyRecoil( nil, damageFrac )

    if CLIENT then return end

    local rf = RecipientFilter()
    rf:AddAllPlayers()

    local pitchMult = Lerp( damageFrac, primary.SoundPitchMultLowCharge, 1 )
    local pitch = math.Rand( primary.SoundPitchMin, primary.SoundPitchMax ) * pitchMult
    local volume = math.max( damageFrac, 0.25 )

    owner:EmitSound( self.Primary.Sound, 90, pitch, volume, CHAN_WEAPON, nil, nil, rf )
    self:SendTranslatedWeaponAnim( ACT_VM_PRIMARYATTACK )
    owner:SetAnimation( PLAYER_ATTACK1 )
end

function SWEP:OnChargeStep( chargeAmount )
    if CLIENT and self:GetOwner() == LocalPlayer() then
        local primary = self.Primary
        local maxCharge = primary.ClipSize
        local baseFrac = chargeAmount / maxCharge
        local vmFrac = primary.ChargeVMShakeStrengthEase( baseFrac )

        self._curChargeVMShakeStrength = vmFrac * primary.ChargeVMShakeStrength
        self._curChargeVMShakeIntervalMin = Lerp( vmFrac, primary.ChargeVMShakeIntervalMinStart, primary.ChargeVMShakeIntervalMinEnd )
        self._curChargeVMShakeIntervalMax = Lerp( vmFrac, primary.ChargeVMShakeIntervalMaxStart, primary.ChargeVMShakeIntervalMaxEnd )
    end
end

function SWEP:OnOvercharged()
    self:SetNextFire( CurTime() + self.Primary.Cooldown )
    --self:SendWeaponAnim( ACT_VM_PRIMARYATTACK )

    if CLIENT then
        self._isChargeVMShakeActive = false

        return
    end

    local owner = self:GetOwner()
    if not IsValid( owner ) then return end

    local recoil = self.Primary.Recoil
    local recoilMin = recoil.MinAng
    local recoilMax = recoil.MaxAng

    owner:ViewPunch( Angle( -math.Rand( recoilMin.p, recoilMax.p ), math.Rand( recoilMin.y, recoilMax.y ), math.Rand( recoilMin.r, recoilMax.r ) ) )

    local pos = owner:GetShootPos() + owner:GetAimVector() * 15

    util.BlastDamage( self, owner, pos, self.Primary.OverchargeExplosionRadius, self.Primary.OverchargeExplosionDamage )

    local eff = EffectData()
    eff:SetOrigin( pos )
    eff:SetMagnitude( 1 )
    eff:SetScale( 1 )
    util.Effect( "Explosion", eff, true, true )

    owner:EmitSound( "ambient/explosions/explode_4.wav", 80, math.Rand( 110, 115 ), 1 )

    timer.Simple( 0, function()
        if not IsValid( self ) then return end

        self:Remove()
    end )
end

function SWEP:Equip()
    BaseClass.Equip( self )

    -- SniperRound doesn't work with the default ammo-init system
    if self:GetReserveAmmo() == 0 then
        self:SetReserveAmmo( self.Primary.DefaultClip )
    end
end

function SWEP:OnStartCharging()
    if CLIENT then
        self._curChargeVMShakeStrength = 0
        self._curChargeVMShakeIntervalMin = self.Primary.ChargeVMShakeIntervalMinStart
        self._curChargeVMShakeIntervalMax = self.Primary.ChargeVMShakeIntervalMaxStart
        self._isChargeVMShakeActive = true
    end

    local timerName = "CFC_PvPWeapons_IonCannon_SpinAnim_" .. self:EntIndex()

    timer.Create( timerName, 0.2, 0, function()
        if not IsValid( self ) or not IsValid( self:GetOwner() ) then
            timer.Remove( timerName )

            return
        end

        self:SendWeaponAnim( ACT_VM_PULLBACK )
    end )
end

function SWEP:OnStopCharging()
    if CLIENT then
        self.ViewOffset = self._baseViewOffset
        self._isChargeVMShakeActive = false
    end

    timer.Remove( "CFC_PvPWeapons_IonCannon_SpinAnim_" .. self:EntIndex() )
end

function SWEP:Reload()
    self:SendWeaponAnim( ACT_VM_RELOAD )

    local owner = self:GetOwner()

    if IsValid( owner ) and owner:KeyPressed( IN_RELOAD ) then
        self:SendWeaponAnim( ACT_VM_IDLE_DEPLOYED_1 )
        owner:SetAnimation( PLAYER_RELOAD )

        timer.Create( "CFC_PvPWeapons_IonCannon_FidgetAnim_EndSound_" .. self:EntIndex(), 0.5, 1, function()
            if not IsValid( self ) then return end

            self:EmitSound( "weapons/gauss/gauss_fidget.wav" )
        end )
    end
end


if CLIENT then
    function SWEP:Initialize()
        BaseClass.Initialize( self )

        local baseViewOffset = self.ViewOffset

        self._curChargeVMShakeStrength = self.Primary.ChargeVMShakeStrength
        self._curChargeVMShakeIntervalMin = self.Primary.ChargeVMShakeIntervalMinStart
        self._curChargeVMShakeIntervalMax = self.Primary.ChargeVMShakeIntervalMaxStart
        self._baseViewOffset = baseViewOffset
        self._targetViewOffset = Vector( baseViewOffset[1], baseViewOffset[2], baseViewOffset[3] )
        self._nextViewOffsetChange = 0
        self._isChargeVMShakeActive = false
        self._isChargeVMShakeLerpMatched = false

        self:SetColor( self.WorldColorOverride )
    end

    function SWEP:ChargeVMShake()
        if not self._isChargeVMShakeActive then return end

        self:ChargeVMShakeChange()

        if self._isChargeVMShakeLerpMatched then return end

        local viewOffset = self.ViewOffset
        local targetOffset = self._targetViewOffset

        if viewOffset:Distance( targetOffset ) < 0.01 then
            self.ViewOffset = targetOffset
            self._isChargeVMShakeLerpMatched = true
        else
            self.ViewOffset = LerpVector( FrameTime() * self.Primary.ChargeVMShakeLerp, viewOffset, targetOffset )
        end
    end

    function SWEP:ChargeThink()
        if self:GetOwner() == LocalPlayer() then
            self:ChargeVMShake()
        end
    end

    function SWEP:ChargeVMShakeChange()
        local nextChangeTime = self._nextViewOffsetChange
        local now = CurTime()

        if now >= nextChangeTime then
            local primary = self.Primary
            local shakeStrength = self._curChargeVMShakeStrength
            local speedBonus = primary.ChargeVMShakeStrengthMovementBonus
            local interval = math.Rand( self._curChargeVMShakeIntervalMin, self._curChargeVMShakeIntervalMax )

            if speedBonus ~= 0 then
                shakeStrength = shakeStrength * ( LocalPlayer():GetVelocity():Length() * speedBonus + 1 )
            end

            self._nextViewOffsetChange = now + interval
            self._targetViewOffset = self._baseViewOffset + Vector( math.Rand( -shakeStrength, shakeStrength ), math.Rand( -shakeStrength, shakeStrength ), math.Rand( -shakeStrength, shakeStrength ) )
            self._isChargeVMShakeLerpMatched = false
        end
    end

    function SWEP:Holster()
        self.ViewOffset = self._baseViewOffset
        self._isChargeVMShakeActive = false

        return BaseClass.Holster( self )
    end
end


----- PRIVATE FUNCTIONS -----

if SERVER then
    doExplosiveDamage = function( wep, owner, damage, radius, damageFrac )
        local pullback = 1 -- Pull the explosion position back this much along the line, to avoid it getting stuck on the surface

        local startPos = owner:GetShootPos()
        local dir = owner:GetAimVector()
        local trRequest = {
            start = startPos,
            endpos = startPos + dir * 10000,
            filter = owner,
            mins = VECTOR_ZERO,
            maxs = VECTOR_ZERO,
        }

        owner:LagCompensation( true )
            local tr = util.TraceHull( trRequest )
        owner:LagCompensation( false )

        if not tr.Hit then return end

        local hitPos = tr.HitPos
        local dmgPos = hitPos - dir * pullback
        local falloffMult = wep:GetDamageFalloff( startPos:Distance( hitPos ) )

        damage = damage * falloffMult
        radius = radius * falloffMult

        util.BlastDamage( wep, owner, dmgPos, radius, damage )

        local eff = EffectData()
        eff:SetOrigin( dmgPos )
        eff:SetMagnitude( 2.5 * damageFrac )
        eff:SetScale( 1.75 * damageFrac )
        eff:SetRadius( radius * 0.8 )
        eff:SetNormal( tr.HitNormal )
        util.Effect( "AR2Explosion", eff, true, true )
        util.Effect( "Sparks", eff, true, true )

        local rf = RecipientFilter()
        rf:AddAllPlayers()

        EmitSound( wep.Primary.ExplosionSound, dmgPos, 0, CHAN_AUTO, wep.Primary.ExplosionVolume * damageFrac * falloffMult, 80, 0, wep.Primary.ExplosionPitch, 0, rf )
    end
end