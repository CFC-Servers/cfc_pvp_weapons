AddCSLuaFile()

if CLIENT then
    language.Add( "cfc_gamblers_revolver_gold_ammo", "Gambling Chips" )
end

game.AddAmmoType( { name = "cfc_gamblers_revolver_gold", maxcarry = 1000 } )

DEFINE_BASECLASS( "cfc_gamblers_revolver" )
SWEP.Base = "cfc_gamblers_revolver"

-- UI stuff

SWEP.PrintName = "Jackpot Revolver"
SWEP.Category = "CFC"

SWEP.AutoSwitchTo = true
SWEP.AutoSwitchFrom = false
SWEP.Weight = 1000

SWEP.Slot = 1
SWEP.Spawnable = true
SWEP.AdminOnly = true
SWEP.Instructions = "A gun that feels like a million bucks..."

if CLIENT then
    CFCPvPWeapons.CL_SetWeaponSelectIcon( SWEP, "cfc_gamblers_revolver", "materials/vgui/hud/cfc_gamblers_revolver_golden.png" )
end

-- Appearance

SWEP.UseHands = true -- If your viewmodel includes it's own hands (v_ model instead of a c_ model), set this to false

SWEP.ViewModelTargetFOV = 65
SWEP.ViewModel = Model( "models/weapons/cfc_gamblers_revolver/v_gun.mdl" ) -- Weapon viewmodel, usually a c_ or v_ model
SWEP.WorldModel = Model( "models/weapons/cfc_gamblers_revolver/w_gun.mdl" ) -- Weapon worldmodel, almost always a w_ model

SWEP.HoldType = "revolver" -- https://wiki.facepunch.com/gmod/Hold_Types
SWEP.CustomHoldType = {} -- Allows you to override any hold type animations with your own, uses [ACT_MP_STAND_IDLE] = ACT_HL2MP_IDLE_SHOTGUN formatting

-- Weapon stats

SWEP.Firemode = 0 -- The default firemode, -1 = full-auto, 0 = semi-auto, >1 = burst fire

SWEP.Primary = {
    Ammo = "cfc_gamblers_revolver_gold", -- The ammo type used when reloading
    Cost = 1, -- The amount of ammo used per shot

    ClipSize = 6, -- The amount of ammo per magazine, -1 to have no magazine (pull from reserves directly)
    DefaultClip = 66 + 6, -- How many rounds the player gets when picking up the weapon for the first time, excess ammo will be added to the player's reserves

    Damage = 1, -- Damage per shot (ignored for this weapon)
    Count = 1, -- Optional: Shots fired per shot

    PumpAction = false, -- Optional: Tries to pump the weapon between shots
    PumpSound = "Weapon_Shotgun.Special1", -- Optional: Sound to play when pumping

    Delay = 60 / 115, -- Delay between shots, use 60 / x for RPM (Rounds per minute) values
    BurstDelay = 60 / 1200, -- Burst only: the delay between shots during a burst
    BurstEndDelay = 0.4, -- Burst only: the delay added after a burst

    Range = 20000, -- The range at which the weapon can hit a plate with a diameter of <Accuracy> units
    Accuracy = 12, -- The reference value to use for the previous option, 12 = headshots, 24 = bodyshots

    RangeModifier = 1, -- The damage multiplier applied for every 1000 units a bullet travels, e.g. 0.85 for 2000 units = 0.85 * 0.85 = 72% of original damage

    Recoil = {
        MinAng = Angle( 1, -0.3, 0 ), -- The minimum amount of recoil punch per shot
        MaxAng = Angle( 1.2, 0.3, 0 ), -- The maximum amount of recoil punch per shot
        Punch = 0.2, -- The percentage of recoil added to the player's view angles, if set to 0 a player's view will always reset to the exact point they were aiming at
        Ratio = 0.4 -- The percentage of recoil that's translated into the viewmodel, higher values cause bullets to end up above the crosshair
    },

    Reload = {
        Time = 0, -- Optional: The time it takes for the weapon to reload (only supports non-shotgun reloads, defaults to animation duration)
        Amount = math.huge, -- Optional: Amount of ammo to reload per reload
        Shotgun = false, -- Optional: Interruptable shotgun reloads
        Sound = "Weapon_Pistol.Reload" -- Optional: Sound to play when starting a reload
    },

    Sound = "Weapon_cfc_gamblers_revolver.single", -- Firing sound
    TracerName = "Tracer", -- Tracer effect, leave blank for no tracer
    TracerFrequency = 1,
}

SWEP.ViewOffset = Vector( 0, 0, 0 ) -- Optional: Applies an offset to the viewmodel's position

SWEP.AllowMultiplePickup = true

SWEP.DropOnDeath = true
SWEP.DropCleanupDelay = 240
SWEP.RetainAmmoOnDrop = true
SWEP.DoOwnerChangedEffects = true

SWEP.DoCollisionEffects = true
SWEP.HasFunHeavyPhysics = true

SWEP.KillIconPrefix = "cfc_gamblers_revolver_golden_"
SWEP.KillIconDefault = "regular"

if CLIENT then
    SWEP.CritSpriteMat = Material( "sprites/light_glow02_add" )
    SWEP.CritSpriteColor = Color( 255, 175, 50 )
    SWEP.CritSpriteOffset = Vector( 10, 0, -4 )
    SWEP.CritSpriteSize = 64
end

SWEP.CFCPvPWeapons_HitgroupNormalizeTo = { -- Make the head hitgrouip be the only one to scale damage.
    [HITGROUP_CHEST] = 1,
    [HITGROUP_STOMACH] = 1,
    [HITGROUP_LEFTARM] = 1,
    [HITGROUP_RIGHTARM] = 1,
    [HITGROUP_LEFTLEG] = 1,
    [HITGROUP_RIGHTLEG] = 1,
    [HITGROUP_GEAR] = 1,
}


CFCPvPWeapons.GamblersRevolver = CFCPvPWeapons.GamblersRevolver or {}
CFCPvPWeapons.GamblersRevolver.SCREENSHAKES = CFCPvPWeapons.GamblersRevolver.SCREENSHAKES or {}
CFCPvPWeapons.GamblersRevolver.SOUNDS = CFCPvPWeapons.GamblersRevolver.SOUNDS or {}

local SCREENSHAKES = CFCPvPWeapons.GamblersRevolver.SCREENSHAKES
local SOUNDS = CFCPvPWeapons.GamblersRevolver.SOUNDS


if CLIENT then
    function SWEP:CalcViewModelView( vm )
        vm:SetSkin( 1 )
    end
end


function SWEP:Initialize()
    BaseClass.Initialize( self )

    -- Can't add to the SWEP table normally, as child classes with fewer entries will have some of these forcibly added in.
    self.Primary.DamageDice = {
        { Damage = 125, Weight = 100, KillIcon = "lucky", Sounds = SOUNDS.LUCKY, Group = "crit", Screenshake = SCREENSHAKES.LUCKY, Tracer = "GaussTracer", },
        { Damage = 5000, Weight = 20, KillIcon = "superlucky", Sounds = SOUNDS.SUPERLUCKY, Group = "crit", HullSize = 1, Screenshake = SCREENSHAKES.SUPERLUCKY, Tracer = "GaussTracer", },
        { Damage = 0, Weight = 3, KillIcon = "unlucky", Sounds = SOUNDS.MISFIRE, SelfDamage = 100000, SelfForce = 5000, BehindDamage = 150, BehindHullSize = 10, DropWeapon = true, },
        { Damage = 6666666, Weight = 0.06, KillIcon = "unholy", Sounds = SOUNDS.UNHOLY, Force = 666, HullSize = 10, Screenshake = SCREENSHAKES.UNHOLY, Tracer = "AirboatGunHeavyTracer", Function = function( wep, outcome, bullet )
            if CLIENT then return end

            wep.CFCPvPWeapons_HitgroupNormalizeTo[HITGROUP_HEAD] = 1 -- Force headshots to have a mult of one temporarily.

            timer.Simple( 0, function()
                if not IsValid( wep ) then return end
                wep.CFCPvPWeapons_HitgroupNormalizeTo[HITGROUP_HEAD] = nil -- Revert back to normal.
            end )

            wep:UnholyBlast( outcome, bullet )
        end },
    }
    table.SortByMember( self.Primary.DamageDice, "Weight", false )

    self.Primary.PointAtSelfOutcomes = {
        { Weight = 5, Sounds = SOUNDS.ROULETTE_EMPTY, },
        { Weight = 1, SelfDamage = 1000, KillIcon = "self", Sounds = SOUNDS.ROULETTE_LOSE, BehindDamage = 150, BehindHullSize = 10, DropWeapon = true, },
    }
    table.SortByMember( self.Primary.PointAtSelfOutcomes, "Weight", false )

    self:SetSkin( 1 )
    self.RenderGroup = RENDERGROUP_TRANSLUCENT
end

function SWEP:SetFirstTimeHints()
    -- Do nothing.
end

function SWEP:ModifyBulletTable( bullet )
    local pitch = math.Clamp( bullet.Damage + math.random( -20, 0 ), 75, 200 )
    self:EmitSound( "physics/metal/metal_canister_impact_hard" .. math.random( 1, 3 ) .. ".wav", 85, pitch, 0.75, CHAN_STATIC )

    return BaseClass.ModifyBulletTable( self, bullet )
end

function SWEP:CanPlayerPickUp( ply )
    if ply:GetAmmoCount( self.Primary.Ammo ) == 0 then return true end
    if ply:KeyDown( IN_USE ) and ply:GetEyeTrace().Entity == self then return true end

    return false
end

function SWEP:DropOnDeathFX( _owner )
    self:EmitSound( "physics/metal/metal_canister_impact_soft" .. math.random( 1, 3 ) .. ".wav", 90, math.random( 90, 110 ), 1, CHAN_STATIC )
end

function SWEP:OnPickedUpFX()
    self:EmitSound( "physics/metal/metal_canister_impact_soft" .. math.random( 1, 3 ) .. ".wav", 80, math.random( 120, 140 ), 1, CHAN_STATIC )
end

function SWEP:OnDroppedFX()
    self:EmitSound( "physics/metal/metal_canister_impact_soft" .. math.random( 1, 3 ) .. ".wav", 80, math.random( 100, 110 ), 1, CHAN_STATIC )
end

function SWEP:MakeCollisionEffectFunc()
    return function( ent, data )
        local nextSound = ent.cfcPvPWeapons_NextCollideSound or 0
        if nextSound > CurTime() then return end
        ent.cfcPvPWeapons_NextCollideSound = CurTime() + 0.05

        local speed = data.Speed
        if speed < 100 then return end

        local pitch = 140 - math.Clamp( speed / 5, 0, 80 )
        ent:EmitSound( "physics/metal/metal_canister_impact_hard" .. math.random( 1, 2 ) .. ".wav", 90, pitch, 0.9, CHAN_STATIC )

        local effectdata = EffectData()
        effectdata:SetOrigin( data.HitPos )
        effectdata:SetNormal( -data.HitNormal )
        effectdata:SetScale( 1 + speed / 1500 )
        effectdata:SetMagnitude( 1 )
        effectdata:SetRadius( speed / 10 )
        util.Effect( "Sparks", effectdata )
    end
end

if CLIENT then
    function SWEP:ShouldDrawCritSprite()
        return true
    end

    function SWEP:UpdateRenderGroup()
        -- Do nothing, always stay translucent to draw the crit sprite.
    end
end