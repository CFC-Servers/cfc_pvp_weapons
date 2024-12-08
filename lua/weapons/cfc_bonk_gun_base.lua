AddCSLuaFile()

DEFINE_BASECLASS( "cfc_simple_base" )
SWEP.Base = "cfc_simple_base"

-- UI stuff

SWEP.PrintName = "Bonk Gun Base"
SWEP.Category = "CFC"

SWEP.Slot = 1
SWEP.Spawnable = false

-- Appearance

SWEP.UseHands = true -- If your viewmodel includes it's own hands (v_ model instead of a c_ model), set this to false

SWEP.ViewModelTargetFOV = 65
SWEP.ViewModel = Model( "models/weapons/c_pistol.mdl" ) -- Weapon viewmodel, usually a c_ or v_ model
SWEP.WorldModel = Model( "models/weapons/w_pistol.mdl" ) -- Weapon worldmodel, almost always a w_ model

SWEP.HoldType = "pistol" -- https://wiki.facepunch.com/gmod/Hold_Types
SWEP.CustomHoldType = {} -- Allows you to override any hold type animations with your own, uses [ACT_MP_STAND_IDLE] = ACT_HL2MP_IDLE_SHOTGUN formatting

-- Weapon stats

SWEP.Firemode = 0 -- The default firemode, -1 = full-auto, 0 = semi-auto, >1 = burst fire

SWEP.Primary = {
    Ammo = "Pistol", -- The ammo type used when reloading
    Cost = 1, -- The amount of ammo used per shot

    ClipSize = 18, -- The amount of ammo per magazine, -1 to have no magazine (pull from reserves directly)
    DefaultClip = 1000, -- How many rounds the player gets when picking up the weapon for the first time, excess ammo will be added to the player's reserves

    Damage = 13, -- Damage per shot
    Count = 1, -- Optional: Shots fired per shot

    PumpAction = false, -- Optional: Tries to pump the weapon between shots
    PumpSound = "Weapon_Shotgun.Special1", -- Optional: Sound to play when pumping

    Delay = 60 / 600, -- Delay between shots, use 60 / x for RPM (Rounds per minute) values
    BurstDelay = 60 / 1200, -- Burst only: the delay between shots during a burst
    BurstEndDelay = 0.4, -- Burst only: the delay added after a burst

    Range = 750, -- The range at which the weapon can hit a plate with a diameter of <Accuracy> units
    Accuracy = 12, -- The reference value to use for the previous option, 12 = headshots, 24 = bodyshots

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
}

SWEP.ViewOffset = Vector( 0, 0, 0 ) -- Optional: Applies an offset to the viewmodel's position


-- Bonk

SWEP.Bonk = {
    Enabled = true, -- Enables bonking.
    PlayerForce = 750 / 0.7, -- Soft-maximum launch strength for when all bullets hit, assuming no special hitgroups (e.g. only hit the chest).
        PlayerForceAdd = 100, -- Flat addition to the launch strength, after the multiplier is applied.
        PlayerForceMultMax = 0.7, -- Damage mult (normal is 1) cannot exceed this value (otherwise could have massive launches from headshots, etc.).
        PlayerForceComboMult = 1.75, -- Multiplies against force strength if the victim is currently in a bonk state. Requires ImpactEnabled to be true.
        PlayerForceGroundZMult = 0.9, -- Makes ground launches be more vertical, proportionally.
        PlayerForceGroundZAdd = 0.3, -- Makes ground launches be more vertical, additively.
        PlayerForceGroundZMin = 250, -- Minimim z-component of launch force when on the ground. Gmod keeps players grounded unless the the z-vel is ~248.13 or above.
        PlayerForceAirMult = 1.15, -- Multiplies against force strength if the victim is in the air when hit.
        PlayerForceAirZMult = 1, -- Makes air launches be more vertical, proportionally.
        PlayerForceAirZAdd = 0.1, -- Makes air launches be more vertical, additively.
        PlayerForceCounteractMult = 0.8, -- How strongly (0-1) the victim's velocity will be counteracted by the launch, if they were moving opposite to it.
        PlayerForceIgnoreThreshold = 0.2, -- If the damage multiplier is below this, the player won't be launched.
        NPCForceMult = 1.75, -- Multiplies against launch strength for NPCs.
        NPCForceGroundHorizontalMult = 3, -- Multiplies against horizontal launch strength for NPCs when on the ground.
    PlayerForceMultRagdoll = 300, -- When the shot is enough to kill, the above values are ignored and this is used instead as a multiplier against dmgForce.
    PropForceMult = 15, -- Multiplier against dmgForce when shooting props.
    AirShotsRefundAmmo = 0, -- Ammo refunded when shooting a midair, currently bonked target. Requires ImpactEnabled to be true.
    ImpactEnabled = true, -- If enabled, victims will take damage upon impacting a surface after getting bonked. This is also what enables tracking of the 'bonk status' of victims.
        ImpactDamageMult = 12 / 20000,
        ImpactDamageMin = 5,
        ImpactDamageMax = 60,
    SelfForce = Vector( 300, 300, 420 ), -- Self-knockback when shooting while in the air. False to disable this and SelfDamage.
        SelfDamage = 6, -- Damage dealt to self when shooting while in the air. 0 to not deal any damage.
        SelfForceOnGround = false, -- If true, will apply self force even while on the ground.
    DisableMovementDuration = 0.7, -- How long to disable movement for when bonked. Ends early on impact. 0 to disable.
}


if CLIENT then
    function SWEP:FireWeapon()
        local ply = self:GetOwner()

        -- If in buildmode, do self-knockback and sounds, but no bullets
        if ply.IsInBuild and ply:IsInBuild() then
            self:EmitFireSound()
            self:SendTranslatedWeaponAnim( ACT_VM_PRIMARYATTACK )
            ply:SetAnimation( PLAYER_ATTACK1 )

            return
        end

        BaseClass.FireWeapon( self )
    end

    return
end


function SWEP:FireWeapon()
    local selfForce = self.Bonk.SelfForce
    if not selfForce then return BaseClass.FireWeapon( self ) end

    local ply = self:GetOwner()
    if not IsValid( ply ) or not ply:IsPlayer() then return BaseClass.FireWeapon( self ) end

    local onGround = ply:IsOnGround()

    -- Self-knockback and self-damage when shooting while in the air
    if self.Bonk.SelfForceOnGround or not onGround then
        local dir = -ply:GetAimVector()

        if onGround then
            dir.z = math.max( dir.z, 0.5 )
        end

        ply:SetVelocity( dir * selfForce ) -- SetVelocity() when used on a player is additive

        local selfDamage = self.Bonk.SelfDamage
        if selfDamage > 0 then
            ply:TakeDamage( selfDamage, ply, self )
            ply:EmitSound( "physics/body/body_medium_impact_soft" .. math.random( 1, 7 ) .. ".wav", 85 )
        end
    end

    -- If in buildmode, do self-knockback and sounds, but no bullets
    if ply.IsInBuild and ply:IsInBuild() then
        self:EmitFireSound()
        self:SendTranslatedWeaponAnim( ACT_VM_PRIMARYATTACK )
        ply:SetAnimation( PLAYER_ATTACK1 )

        return
    end

    BaseClass.FireWeapon( self )
end
