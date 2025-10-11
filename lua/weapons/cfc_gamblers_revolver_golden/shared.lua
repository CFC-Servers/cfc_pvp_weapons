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

SWEP.Slot = 1
SWEP.Spawnable = true
SWEP.AdminOnly = true

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
}

SWEP.ViewOffset = Vector( 0, 0, 0 ) -- Optional: Applies an offset to the viewmodel's position
SWEP.KillIconPrefix = "cfc_gamblers_revolver_golden_"
SWEP.KillIconDefault = "regular"

SWEP.CFCPvPWeapons_HitgroupNormalizeTo = { -- Make the head hitgrouip be the only one to scale damage.
    [HITGROUP_CHEST] = 1,
    [HITGROUP_STOMACH] = 1,
    [HITGROUP_LEFTARM] = 1,
    [HITGROUP_RIGHTARM] = 1,
    [HITGROUP_LEFTLEG] = 1,
    [HITGROUP_RIGHTLEG] = 1,
    [HITGROUP_GEAR] = 1,
}


if CLIENT then
    function SWEP:CalcViewModelView( vm )
        vm:SetSkin( 1 )
    end
end


function SWEP:Initialize()
    BaseClass.Initialize( self )

    -- Can't add to the SWEP table normally, as child classes with fewer entries will have some of these forcibly added in.
    self.Primary.DamageDice = {
        { Damage = 125, Weight = 100, KillIcon = "lucky", Sound = "physics/glass/glass_impact_bullet4.wav", Group = "crit", },
        { Damage = 5000, Weight = 20, KillIcon = "superlucky", Sound = "physics/glass/glass_largesheet_break1.wav", Group = "crit", },
        { Damage = 0, Weight = 3, KillIcon = "unlucky", Sound = "npc/manhack/gib.wav", SoundPitch = 130, SelfDamage = 100000, SelfForce = 5000, },
        { Damage = 666666, Weight = 0.06, KillIcon = "unholy", Sound = "npc/strider/striderx_alert5.wav", SoundPitch = 40, Force = 666, Function = function( wep )
            wep.CFCPvPWeapons_HitgroupNormalizeTo[HITGROUP_HEAD] = 1 -- Force headshots to have a mult of one temporarily.

            timer.Simple( 0, function()
                if not IsValid( wep ) then return end
                wep.CFCPvPWeapons_HitgroupNormalizeTo[HITGROUP_HEAD] = nil -- Revert back to normal.
            end )
        end },
    }
    table.SortByMember( self.Primary.DamageDice, "Weight", false )

    self.Primary.PointAtSelfOutcomes = {
        { Weight = 5, Sound = "weapons/pistol/pistol_empty.wav", SoundChannel = CHAN_STATIC, },
        { Weight = 1, SelfDamage = 1000, KillIcon = "self", Sound = self.Primary.Sound, },
    }
    table.SortByMember( self.Primary.PointAtSelfOutcomes, "Weight", false )

    self:SetSkin( 1 )
end

function SWEP:SetFirstTimeHints()
    -- Do nothing.
end
