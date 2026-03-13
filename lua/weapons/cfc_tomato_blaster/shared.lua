AddCSLuaFile()

DEFINE_BASECLASS( "cfc_charged_blaster_base" )
SWEP.Base = "cfc_charged_blaster_base"

-- UI stuff

SWEP.PrintName = "Tomato Blaster"
SWEP.Category = "CFC"

SWEP.Slot = 4
SWEP.Spawnable = true
SWEP.AdminOnly = true

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

    ProjectileSpeedMin = 1100, -- Minimum projectile speed.
    ProjectileSpeedMax = 1300, -- Maximum projectile speed.
    ProjectileStartFadeDelay = 0, -- Delay before projectiles start fading. 0 to disable (you must have another way for the projectiles to auto-delete).
    ProjectileFadeDuration = 0, -- Duration of projectile fade. 0 to delete instantly.
    ProjectileCleanupOnRemove = true, -- Whether to instantly delete all projectiles when the weapon is removed.

    PumpAction = false, -- Optional: Tries to pump the weapon between shots
    PumpSound = "Weapon_Shotgun.Special1", -- Optional: Sound to play when pumping

    Delay = 0.075, -- Delay between each buildup of charge, use 60 / x for RPM (Rounds per minute) values
    BurstEnabled = true, -- When releasing the charge, decides whether to burst-fire the weapon once per unit ammo, or to expend the full charge in one fire call
    BurstDelay = 0.1, -- Burst only: the delay between shots during a burst
    Cooldown = 2, -- Cooldown to apply once the charge is expended
    MovementMultWhenCharging = 0.75, -- Multiplier against movement speed when charging
    OverchargeDelay = false, -- Once at full charge, it takes this long before overcharge occurs. False to disable.

    Range = 300, -- The range at which the weapon can hit a plate with a diameter of <Accuracy> units
    Accuracy = 24, -- The reference value to use for the previous option, 12 = headshots, 24 = bodyshots

    RangeModifier = 0.85, -- The damage multiplier applied for every 1000 units a bullet travels, e.g. 0.85 for 2000 units = 0.85 * 0.85 = 72% of original damage

    Recoil = {
        Ang = Angle( 1, -0.3, 0 ), -- Recoil per shot, static.
        Punch = 0.2, -- The percentage of recoil added to the player's view angles, if set to 0 a player's view will always reset to the exact point they were aiming at
        Ratio = 0.4 -- The percentage of recoil that's translated into the viewmodel, higher values cause bullets to end up above the crosshair
    },
    RecoilCharging = {
        Mult = 0.1, -- If above zero, will repeatedly apply recoil while charging, with this as a strength multiplier. Scales with charge level.
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

    Sound = { -- Firing sound
        Path = "physics/metal/metal_barrel_impact_hard5.wav",
        PitchMin = 150,
        PitchMax = 160,
    },
    Sound2 = { -- Bonus Firing sound
        Path = "physics/metal/metal_computer_impact_soft3.wav",
        PitchMin = 100,
        PitchMax = 110,
        Volume = 0.5,
    },
    TracerName = "", -- Tracer effect, leave blank for no tracer

    ChargeSound = "physics/plastic/plastic_barrel_roll_loop1.wav",
    ChargeVolume = 1,
    ChargeStepSound = "physics/plastic/plastic_box_impact_soft4.wav",
    ChargeStepVolume = 0.3,
    ChargeStepPitchMinStart = 80,
    ChargeStepPitchMaxStart = 80,
    ChargeStepPitchMinEnd = 140,
    ChargeStepPitchMaxEnd = 140,
    ChargeStepPitchEase = function( x ) return x end, -- Use an easing function (e.g. math.ease.InCubic). Default is linear, which isn't in the ease library.

    ChargeSprite = {
        Enabled = false,
        Mat = "sprites/light_glow01", -- Material path for the sprite (should have ignorez)
        MatVM = "cfc_pvp_weapons/sprites/charge_glow", -- Material path for the viewmodel (shouldn't have ignorez)
        Offset = Vector( 25, 0, 0 ), -- Position offset for the sprite
        OffsetVM = Vector( 25, -3, -3 ), -- Position offset for the viewmodel sprite
        Color = Color( 255, 255, 255 ),
        AlphaStart = 0,
        AlphaEnd = 255,
        Framerate = 10,
        ScaleStart = 0, -- Used by the world sprite
        ScaleEnd = 0.75, -- Used by the world sprite
        SizeStart = 0, -- Used by the viewmodel sprite
        SizeEnd = 20, -- Used by the viewmodel sprite
    }
}

SWEP.CFC_FirstTimeHints = {
    {
        Message = "The Tomato Blaster is a charged weapon. Hold left mouse before releasing to fire.",
        Sound = "ambient/water/drip1.wav",
        Duration = 7,
        DelayNext = 5,
    },
    {
        Message = "Splatter someone with a tomato to briefly cover their screen!",
        Sound = "ambient/water/drip2.wav",
        Duration = 7,
        DelayNext = 0,
    },
}

SWEP.ViewOffset = Vector( 0, 0, 0 ) -- Optional: Applies an offset to the viewmodel's position


function SWEP:CreateProjectile( pos, _dir )
    local ent = ents.Create( "cfc_rotten_tomato_projectile" )
    ent:SetPos( pos )
    ent:SetAngles( Angle( math.Rand( -180, 180 ), math.Rand( -180, 180 ), math.Rand( -180, 180 ) ) )
    ent:Spawn()
    ent:SetMaterial( "models/weapons/cfc/tomato" )
    ent:SetOwner( self:GetOwner() )
    ent:SetCreator( self:GetOwner() )
    ent:SetThrower( self:GetOwner() )

    return ent
end

function SWEP:DetermineProjectileVelocity( _ent, dir, speed, owner )
    local vel = dir * speed + owner:GetVelocity()
    local angVel = Vector(
        0,
        ( math.random( 0, 1 ) == 1 and 1 or -1 ) * math.random( 600, 1200 ),
        ( math.random( 0, 1 ) == 1 and 1 or -1 ) * math.random( 600, 1200 )
    )

    return vel, angVel
end

function SWEP:Initialize()
    BaseClass.Initialize( self )

    self:SetColor( Color( 255, 0, 0, 255 ) )
end


if CLIENT then
    function SWEP:PreDrawViewModel( vm, ... )
        BaseClass.PreDrawViewModel( self, vm, ... )

        vm:SetMaterial( "models/weapons/v_models/cfc_tomato_blaster/rocket_launcher_sheet" )
    end

    function SWEP:PostDrawViewModel( vm )
        vm:SetMaterial( "" )
    end
end
