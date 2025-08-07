AddCSLuaFile()

-- Boilerplate lines, required for anything to work at all. cfc_simple_base can be swapped out for different base weapons depending on your needs (e.g. scoped weapons using cfc_simple_base_scoped)

DEFINE_BASECLASS( "cfc_simple_base" )

SWEP.Base = "cfc_simple_base"

-- UI stuff

SWEP.PrintName = "Weapon template" -- The weapon's name used in the spawn menu and HUD
SWEP.Category = "Simple Weapons: Custom" -- The category the weapon will appear in, recommended you use your own if making a pack

SWEP.Slot = 1 -- The slot the weapon will appear in when switching weapons, add 1 to get the actual slot (e.g. a value of 1 translates to weapon slot 2, the pistol slots)

SWEP.Spawnable = false -- Set this to true to make your weapon appear in the spawnmenu, set to false to hide the template

-- Appearance

SWEP.UseHands = true -- If your viewmodel includes its own hands (v_ model instead of a c_ model), set this to false

SWEP.ViewModelTargetFOV = 54 -- The default viewmodel FOV, SWEP.ViewModelFOV gets overwritten by the base itself

SWEP.ViewModel = Model( "models/weapons/c_pistol.mdl" ) -- Weapon viewmodel, usually a c_ or v_ model
SWEP.WorldModel = Model( "models/weapons/w_pistol.mdl" ) -- Weapon worldmodel, almost always a w_ model

SWEP.HoldType = "pistol" -- Default holdtype, you can find all the options here: https://wiki.facepunch.com/gmod/Hold_Types
SWEP.CustomHoldType = {} -- Allows you to override any hold type animations with your own, uses [ACT_MP_STAND_IDLE] = ACT_HL2MP_IDLE_SHOTGUN formatting

-- Weapon stats

SWEP.Firemode = 0 -- The default firemode, -1 = full-auto, 0 = semi-auto, >1 = burst fire

SWEP.Primary = {
    Ammo = "Pistol", -- The ammo type used when reloading. Set to an empty string to not need/use/show ammo
    Cost = 1, -- The amount of ammo used per shot

    ClipSize = 18, -- The amount of ammo per magazine, -1 to have no magazine (pull from reserves directly)
    DefaultClip = 18, -- How many rounds the player gets when picking up the weapon for the first time, excess ammo will be added to the player's reserves

    Damage = 13, -- Damage per shot
    Count = 1, -- Optional: Shots fired per shot

    PumpAction = false, -- Optional: Tries to pump the weapon between shots
    PumpSound = "Weapon_Shotgun.Special1", -- Optional: Sound to play when pumping

    Delay = 60 / 600, -- Delay between shots, use 60 / x for RPM (rounds per minute) values
    BurstDelay = 60 / 1200, -- Burst only: the delay between shots during a burst
    BurstEndDelay = 0.4, -- Burst only: the delay added after a burst

    Range = 750, -- The range at which the weapon can hit a plate with a diameter of <Accuracy> units
    Accuracy = 12, -- The reference value to use for the previous option, 12 = headshots, 24 = bodyshots

    UnscopedRange = 0, -- Scope base only, optional: The range to use when unscoped
    UnscopedAccuracy = 0, -- Scope base only, optional: The accuracy reference to use when unscoped

    RangeModifier = 0.85, -- The damage multiplier applied for every 1000 units a bullet travels, e.g. 0.85 for 2000 units = 0.85 * 0.85 = 72% of original damage

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

    Sound = "Weapon_Pistol.Single", -- Firing sound
    TracerName = "Tracer", -- Tracer effect, leave blank for no tracer

    --[[
        - Fixed spread patterns (Range and Accuracy will be ignored):

        - Grid pattern:
        SpreadPattern = {
            Type = "grid",
            RowCount = 5, -- Ideal number of rows. Number of columns will be auto-calculated based off Primary.Count.
            SpreadX = 0.04, -- Horizontal spread, in radians. Similar to the Spread compnent of the Bullet structure.
            SpreadY = 0.02, -- Vertical spread. Defaults to the value of SpreadX.
        },

        - Ring pattern:
        SpreadPattern = {
            Type = "rings",
            Rings = {
                {
                    Count = 4, -- How many bullets to put in this ring. Note that the bullet total will be clamped by Primary.Count.
                    SpreadX = 0.01, -- Horizontal spread of this ring, in radians.
                    SpreadY = 0.01, -- Vertical spread of this ring, in radians. Defaults to SpreadX.
                    ThetaMult = 1, -- Set to a value between 0 and 1 for a semicircular ring. Defaults to 1.
                    ThetaAdd = 0, -- Rotates the ring. Defaults to 0.
                },
                {
                    Count = 6,
                    SpreadX = 0.01 * 2,
                    SpreadY = 0.01 * 2,
                    ThetaMult = 1,
                    ThetaAdd = 0,
                },
                {
                    Count = 10,
                    SpreadX = 0.01 * 3,
                    SpreadY = 0.01 * 3,
                    ThetaMult = 1,
                    ThetaAdd = 0,
                },
                -- etc
            }
        },

        - Custom pattern:
        SpreadPattern = {
            Type = "custom",
            Func = function( count, spreadInfo, wep )
                -- A function which should return xs, ys; a pair of tables of the x and y spreads for each bullet, in radians.
                -- count: The number of bullets to fire.
                -- spreadInfo: The SpreadPattern table itself.
                -- wep: The weapon instance.
            end,
        }
    --]]
}

SWEP.ViewOffset = Vector( 0, 0, 0 ) -- Optional: Applies an offset to the viewmodel's position

-- Scope base exclusive variables
SWEP.ScopeZoom = 1 -- A number (or table) containing the zoom levels the weapon can cycle through
SWEP.ScopeSound = "Default.Zoom" -- optional: Sound to play when cycling through zoom levels

SWEP.UseScope = false -- Whether this weapon obeys the draw scopes option
SWEP.HideInScope = true -- Whether the viewmodel should be hidden when a scope is being drawn
