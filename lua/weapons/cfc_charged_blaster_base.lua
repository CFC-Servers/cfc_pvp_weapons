AddCSLuaFile()

DEFINE_BASECLASS( "cfc_charge_gun_base" )
SWEP.Base = "cfc_charge_gun_base"

-- UI stuff

SWEP.PrintName = "cfc_charged_blaster_base"
SWEP.Category = "CFC"

SWEP.Slot = 0
SWEP.Spawnable = false
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

    ClipSize = 25, -- The max ammount of ammo for a full charge
    DefaultClip = 1000, -- How many rounds the player gets when picking up the weapon for the first time, excess ammo will be added to the player's reserves

    Damage = 1, -- Damage per shot
    Count = 1, -- Optional: Shots fired per unit ammo

    ProjectileSpeedMin = 1100, -- Minimum projectile speed.
    ProjectileSpeedMax = 1300, -- Maximum projectile speed.
    ProjectileStartFadeDelay = 3, -- Delay before projectiles start fading. 0 to disable (you must have another way for the projectiles to auto-delete).
    ProjectileFadeDuration = 1, -- Duration of projectile fade. 0 to delete instantly.
    ProjectileCleanupOnRemove = true, -- Whether to instantly delete all projectiles when the weapon is removed.

    PumpAction = false, -- Optional: Tries to pump the weapon between shots
    PumpSound = "Weapon_Shotgun.Special1", -- Optional: Sound to play when pumping

    Delay = 0.1, -- Delay between each buildup of charge, use 60 / x for RPM (Rounds per minute) values
    BurstEnabled = true, -- When releasing the charge, decides whether to burst-fire the weapon once per unit ammo, or to expend the full charge in one fire call
    BurstDelay = 0.075, -- Burst only: the delay between shots during a burst
    Cooldown = 2.5, -- Cooldown to apply once the charge is expended
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

    Sound = "physics/concrete/rock_impact_hard2.wav", -- Firing sound
    Sound2 = "doors/door_metal_thin_close2.wav", -- Second firing sound, leave blank for none
    TracerName = "", -- Tracer effect, leave blank for no tracer

    ChargeSound = "npc/combine_gunship/engine_rotor_loop1.wav",
    ChargeVolume = 1,
    ChargeStepSound = "physics/metal/metal_computer_impact_soft2.wav",
    ChargeStepVolume = 0.15,
    ChargeStepPitchMinStart = 60,
    ChargeStepPitchMaxStart = 60,
    ChargeStepPitchMinEnd = 120,
    ChargeStepPitchMaxEnd = 120,
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

SWEP.ViewOffset = Vector( 0, 0, 0 ) -- Optional: Applies an offset to the viewmodel's position


function SWEP:Initialize()
    BaseClass.Initialize( self )

    self._projectiles = {}
end

function SWEP:OnRemove()
    BaseClass.OnRemove( self )

    if CLIENT then return end

    local shouldRemove = self.Primary.ProjectileCleanupOnRemove

    for _, proj in ipairs( self._projectiles ) do
        if proj:IsValid() then
            timer.Remove( "CFC_ChargedBlasterBase_StartFadingProjectile_" .. proj:EntIndex() )
            timer.Remove( "CFC_ChargedBlasterBase_FadeProjectile_" .. proj:EntIndex() )

            if shouldRemove then
                proj:Remove()
            end
        end
    end
end

function SWEP:CreateProjectile( pos, dir )
    local ent = ents.Create( "prop_physics" )
    ent:SetPos( pos )
    ent:SetAngles( dir:Angle() )
    ent:SetModel( "models/hunter/blocks/cube025x025x025.mdl" )
    ent:SetCollisionGroup( COLLISION_GROUP_PROJECTILE )
    ent:SetOwner( self:GetOwner() )
    ent:Spawn()
    ent:SetPhysicsAttacker( self:GetOwner(), 1000 )

    return ent
end

function SWEP:FireWeapon( chargeAmount, notFirstCall )
    if chargeAmount > 1 then
        for _ = 1, chargeAmount do
            self:FireWeapon( 1, true )
        end

        local recoil = self.Primary.Recoil

        self:ApplyStaticRecoil( self.Primary.Recoil.Ang, recoil, chargeAmount, true )

        return
    end

    local owner = self:GetOwner()
    if not IsValid( owner ) then return end

    local aimDir = owner:GetAimVector()

    if not notFirstCall then
        local recoil = self.Primary.Recoil

        self:ApplyStaticRecoil( recoil.Ang, recoil, chargeAmount, true )
    end

    if CLIENT then return end

    local dir = self:SpreadDirection( aimDir )
    local pos

    if self:IsCloseToWall() then
        pos = owner:GetShootPos()
    else
        pos = owner:GetShootPos()
        local ownerVel = owner:GetVelocity()
        local velAccount = ownerVel * FrameTime() * 7

        velAccount = dir * math.Max( velAccount:Dot( dir ), 0 )
        pos = pos + dir * 35 + velAccount
    end

    pos = pos + dir:Angle():Right() * 7

    local proj = self:CreateProjectile( pos, dir )

    if self.Primary.Sound ~= "" then
        proj:EmitSound( self.Primary.Sound )
    end

    if self.Primary.Sound2 ~= "" then
        proj:EmitSound( self.Primary.Sound2 )
    end

    local physObj = proj:GetPhysicsObject()

    if IsValid( physObj ) then
        local speed = math.Rand( self.Primary.ProjectileSpeedMin, self.Primary.ProjectileSpeedMax )

        physObj:SetVelocity( dir * speed + owner:GetVelocity() )
    end

    table.insert( self._projectiles, proj )

    if self.Primary.ProjectileStartFadeDelay <= 0 then return end

    -- Fade projectile later
    timer.Create( "CFC_ChargedBlasterBase_StartFadingProjectile_" .. proj:EntIndex(), self.Primary.ProjectileStartFadeDelay, 1, function()
        if not proj:IsValid() then return end

        proj:SetCollisionGroup( COLLISION_GROUP_WORLD )

        local fadeDuration = self.Primary.ProjectileFadeDuration

        if fadeDuration <= 0 then
            table.RemoveByValue( self._projectiles, proj )
            proj:Remove()

            return
        end

        local fadeStep = 0.1
        local numFadeSteps = math.ceil( fadeDuration / fadeStep )
        local stepsLeft = numFadeSteps
        local startingAlpha = proj:GetColor().a

        proj:SetRenderMode( RENDERMODE_TRANSCOLOR )

        timer.Create( "CFC_ChargedBlasterBase_FadeProjectile_" .. proj:EntIndex(), fadeStep, numFadeSteps, function()
            if not proj:IsValid() then return end

            stepsLeft = stepsLeft - 1

            if stepsLeft <= 0 then
                table.RemoveByValue( self._projectiles, proj )
                proj:Remove()
            else
                local color = proj:GetColor()
                color.a = startingAlpha * stepsLeft / numFadeSteps
                proj:SetColor( color )
            end
        end )
    end )
end

function SWEP:IsCloseToWall()
    local owner = self:GetOwner()
    if not IsValid( owner ) then return false end

    local tr = util.TraceLine( {
        start = owner:GetShootPos(),
        endpos = owner:GetShootPos() + owner:GetAimVector() * 40,
        filter = owner,
        mask = MASK_SHOT_HULL,
    } )

    return tr.Hit
end

function SWEP:SpreadDirection( dir )
    local spread = self:GetSpread()[1] -- simple_base returns as a vector
    if spread == 0 then return dir end

    spread = math.deg( spread )

    local ang = dir:Angle()
    local dirAng = Angle( ang.p, ang.y, ang.r )

    dirAng:RotateAroundAxis( ang:Right(), math.Rand( -spread, spread ) )
    dirAng:RotateAroundAxis( ang:Up(), math.Rand( -spread, spread ) )

    return dirAng:Forward()
end
