AddCSLuaFile()

DEFINE_BASECLASS( "cfc_simple_base_scoped" )
SWEP.Base = "cfc_simple_base_scoped"

-- UI stuff

SWEP.PrintName = "Bonk Rifle"
SWEP.Category = "CFC"
SWEP.Author = "Ze"
SWEP.Instructions = "A scoped alternative to the Bonk Shotgun. Optimized for counter-sniping, anti-airborne personnel engagements, and combo attacks. Don't try this at close range."

SWEP.CFC_FirstTimeHints = {
    {
        Message = "This weapon grows more powerful the further you are from the target. Keep your distance and use the scope.",
        Sound = "ambient/water/drip1.wav",
        Duration = 8,
        DelayNext = 5,
    },
    {
        Message = "Firing while airborne launches you backward. Aim down to boost yourself upward, but beware of the self-damage.",
        Sound = "ambient/water/drip2.wav",
        Duration = 10,
        DelayNext = 6,
    },
    {
        Message = "Sucessful hits deal immense knockback to your target, try to hit them into walls or off ledges for extra damage.",
        Sound = "ambient/water/drip1.wav",
        Duration = 10,
        DelayNext = 0,
    },
}

local bonusHintCooldown = 20
local bonusHints = {
    {
        Message = "Make sure to keep your distance from your target. The Bonk Rifle is a long-range weapon, and will deal less damage the closer you are.",
        Sound = "ambient/water/drip1.wav",
        Duration = 8,
        DelayNext = 0,
    },
}

local BONUS_HINTS_UNDERSTOOD

if SERVER then
    util.AddNetworkString( "CFC_PvPWeapons_BonkRifle_PlayBonusHints" )
    util.AddNetworkString( "CFC_PvPWeapons_BonkRifle_UnderstandBonusHints" )
else
    BONUS_HINTS_UNDERSTOOD = CreateClientConVar( "cfc_pvp_weapons_bonk_rifle_bonus_hints_understood", "0", true, true, "", 0, 1 )
end

SWEP.Slot = 4
SWEP.Spawnable = true

-- Appearance

SWEP.UseHands = true -- If your viewmodel includes it's own hands (v_ model instead of a c_ model), set this to false

SWEP.ViewModelTargetFOV = 65
SWEP.ViewModel = Model( "models/weapons/v_remington_7615p.mdl" ) -- Weapon viewmodel, usually a c_ or v_ model

SWEP.WorldModel = Model( "models/weapons/w_remington_7615p.mdl" ) -- Weapon worldmodel, almost always a w_ model
SWEP.ViewModelFlip = true

SWEP.HoldType = "shotgun" -- https://wiki.facepunch.com/gmod/Hold_Types
SWEP.CustomHoldType = {} -- Allows you to override any hold type animations with your own, uses [ACT_MP_STAND_IDLE] = ACT_HL2MP_IDLE_SHOTGUN formatting



-- Weapon stats

SWEP.Firemode = 0 -- The default firemode, -1 = full-auto, 0 = semi-auto, >1 = burst fire

SWEP.Primary = {
    Ammo = "AR2", -- The ammo type used when reloading
    Cost = 1, -- The amount of ammo used per shot

    ClipSize = 2, -- The amount of ammo per magazine, -1 to have no magazine (pull from reserves directly)
    DefaultClip = 1000, -- How many rounds the player gets when picking up the weapon for the first time, excess ammo will be added to the player's reserves

    Damage = 20, -- Damage per shot
    Count = 1, -- Optional: Shots fired per shot

    PumpAction = true, -- Optional: Tries to pump the weapon between shots
    PumpSound = "Weapon_Shotgun.Special1", -- Optional: Sound to play when pumping

    Delay = 60 / 390, -- Delay between shots, use 60 / x for RPM (Rounds per minute) values
    BurstDelay = 60 / 1200, -- Burst only: the delay between shots during a burst
    BurstEndDelay = 0.4, -- Burst only: the delay added after a burst

    Range = 7000, -- The range at which the weapon can hit a plate with a diameter of <Accuracy> units
    Accuracy = 3, -- The reference value to use for the previous option, 12 = headshots, 24 = bodyshots
    UnscopedAccuracy = 675, -- The accuracy of the weapon when not scoped
    MinEffectiveRange = 3000, -- Damage ramps up from zero to full at this distance
    RangeModifier = 1, -- The damage multiplier applied for every 1000 units a bullet travels, e.g. 0.85 for 2000 units = 0.85 * 0.85 = 72% of original damage

    Recoil = {
        MinAng = Angle( 1, -0.3, 0 ), -- The minimum amount of recoil punch per shot
        MaxAng = Angle( 2.3, 0.6, 0 ), -- The maximum amount of recoil punch per shot
        Punch = 0.7, -- The percentage of recoil added to the player's view angles, if set to 0 a player's view will always reset to the exact point they were aiming at
        Ratio = 0.5 -- The percentage of recoil that's translated into the viewmodel, higher values cause bullets to end up above the crosshair
    },

    Reload = {
        Time = 3.15, -- Optional: The time it takes for the weapon to reload (only supports non-shotgun reloads, defaults to animation duration)
        Amount = 2, -- Optional: Amount of ammo to reload per reload
        Shotgun = false, -- Optional: Interruptable shotgun reloads
        Sound = "Weapon_Shotgun.Reload" -- Optional: Sound to play when starting a reload
    },

    Sound = "Airboat.FireGunHeavy", -- Firing sound
    TracerName = "AirboatGunHeavyTracer", -- Tracer effect, leave blank for no tracer
    TracerFrequency = 1,
}

SWEP.ViewOffset = Vector( 0, 0, 0 ) -- Optional: Applies an offset to the viewmodel's position
SWEP.RunSightsPos = Vector( -2.3095, -3.0514, 2.3965 )
SWEP.RunSightsAng = Angle( -19.8471, -33.9181, 10 )

if CLIENT then
    local ZERO_ANGLE = Angle( 0, 0, 0 )

    function SWEP:GetViewModelPosition( pos, ang )
        local owner = self:GetOwner()
        local sprinting = IsValid( owner ) and owner:IsPlayer() and owner:KeyDown( IN_SPEED )
        local target = sprinting and 1 or 0

        self.SprintPoseBlend = math.Approach( self.SprintPoseBlend or 0, target, FrameTime() * 10 )
        local blend = self.SprintPoseBlend

        pos, ang = LocalToWorld( self.ViewOffset, ZERO_ANGLE, pos, ang )

        ang:RotateAroundAxis( ang:Right(), self.RunSightsAng.p * blend )
        ang:RotateAroundAxis( ang:Up(), self.RunSightsAng.y * blend )
        ang:RotateAroundAxis( ang:Forward(), self.RunSightsAng.r * blend )

        pos = pos + self.RunSightsPos.x * blend * ang:Right()
        pos = pos + self.RunSightsPos.y * blend * ang:Forward()
        pos = pos + self.RunSightsPos.z * blend * ang:Up()

        return pos, ang
    end
end

    local gunMat = Material( "models/weapons/v_models/cfc_bonk_rifle/bonkriflerevised" )

    function SWEP:PreDrawViewModel()
        if self:GetScopeIndex() ~= 0 then
            render.MaterialOverrideByIndex( 0, nil )
            return true
        end

        render.MaterialOverrideByIndex( 0, gunMat )
    end

    function SWEP:PostDrawViewModel()
        render.MaterialOverrideByIndex( 0, nil )
    end

    local worldMat = Material( "models/weapons/w_models/cfc_bonk_rifle/bonkriflerevised" )

    function SWEP:DrawWorldModel()
        render.MaterialOverrideByIndex( 0, worldMat )
        self:DrawModel()
        render.MaterialOverrideByIndex( 0, nil )
    end

-- Scope base exclusive variables
SWEP.ScopeZoom = 10 -- A number (or table) containing the zoom levels the weapon can cycle through
SWEP.ScopeSound = "Default.Zoom" -- optional: Sound to play when cycling through zoom levels

SWEP.UseScope = true -- Whether this weapon obeys the draw scopes option
SWEP.HideInScope = true -- Whether the viewmodel should be hidden when a scope is being drawn


function SWEP:EmitFireSound()
    self:EmitSound( "weapons/shotgun/shotgun_fire6.wav", 80, 105, 0.6, CHAN_WEAPON )
    self:EmitSound( "weapons/shotgun/shotgun_fire6.wav", 80, 110, 0.6, CHAN_AUTO )
    self:EmitSound( "npc/scanner/scanner_nearmiss1.wav", 80, 110, 1, CHAN_AUTO )

    timer.Create( "CFCBonkShotgun_CockSound_" .. self:EntIndex(), 0.3, 1, function()
        if not IsValid( self ) then return end

        self:EmitSound( "weapons/shotgun/shotgun_cock.wav", 70, 110, 0.4, CHAN_WEAPON )
    end )
end

-- Bonk

SWEP.Bonk = {
    Enabled = true, -- Enables bonking.
    PlayerForce = 900, -- Soft-maximum launch strength for when all bullets hit, assuming no special hitgroups (e.g. only hit the chest).
        PlayerForceAdd = 150, -- Flat addition to the launch strength, after the multiplier is applied.
        PlayerForceMultMax = 1, -- Damage mult (normal is 1) cannot exceed this value (otherwise could have massive launches from headshots, etc.).
        PlayerForceComboMult = 3, -- Multiplies against force strength if the victim is currently in a bonk state. Requires ImpactEnabled to be true.
        PlayerForceGroundPitchMin = 25, -- The minimum launch pitch when on the ground.
        PlayerForceGroundZAdd = 50, -- Adds to the z-component of launch force when on the ground.
        PlayerForceGroundThreshold = 60, -- Count the victim as being grounded (minus the z-add) if they are within this many hmu of the ground.
        PlayerForceAirMult = 3, -- Multiplies against force strength if the victim is in the air when hit.
        PlayerForceCounteractMult = 0.8, -- How strongly (0-1) the victim's velocity will be counteracted by the launch, if they were moving opposite to it.
        PlayerForceIgnoreThreshold = 0.2, -- If the damage multiplier is below this, the player won't be launched.
        NPCForceMult = 3, -- Multiplies against launch strength for NPCs.
    PlayerForceMultRagdoll = 500, -- When the shot is enough to kill, the above values are ignored and this is used instead as a multiplier against dmgForce.
    PropForceMult = 30, -- Multiplier against dmgForce when shooting props.
    AirShotsRefundAmmo = 0, -- Ammo refunded when shooting a midair, currently bonked target. Requires ImpactEnabled to be true.
    ImpactEnabled = true, -- If enabled, victims will take damage upon impacting a surface after getting bonked. This is also what enables tracking of the 'bonk status' of victims.
        ImpactDamageMult = 20 / 20000,
        ImpactDamageMin = 5,
        ImpactDamageMax = 150,
    SelfForce = Vector( 400, 250, 600 ), -- Self-knockback when shooting while in the air. False to disable this and SelfDamage.
        SelfDamage = 13, -- Damage dealt to self when shooting while in the air. 0 to not deal any damage.
        SelfForceOnGround = false, -- If true, will apply self force even while on the ground.
    DisableMovementDuration = 0.9, -- How long to disable movement for when bonked. Ends early on impact. 0 to disable.
}



function SWEP:GetDamageFalloff( distance )
    local falloff = BaseClass.GetDamageFalloff( self, distance )
    local minRange = self.Primary.MinEffectiveRange

    if minRange > 0 and distance < minRange then
        falloff = falloff * ( distance / minRange )
    end

    return falloff
end

function SWEP:CanPrimaryFire()
    local owner = self:GetOwner()

    if IsValid( owner ) and owner:IsPlayer() and owner:KeyDown( IN_SPEED ) then
        return false
    end

    return BaseClass.CanPrimaryFire( self )
end

function SWEP:CanAltFire()
    local owner = self:GetOwner()

    if IsValid( owner ) and owner:IsPlayer() and owner:KeyDown( IN_SPEED ) then
        return false
    end

    return BaseClass.CanAltFire( self )
end

function SWEP:Think()
    BaseClass.Think( self )

    local owner = self:GetOwner()
    if not IsValid( owner ) or not owner:IsPlayer() then return end
    if not owner:KeyDown( IN_SPEED ) or self:GetScopeIndex() == 0 then return end

    self:SetScopeIndex( 0 )
    self:UpdateFOV( 0.2 )
end

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

    net.Receive( "CFC_PvPWeapons_BonkRifle_PlayBonusHints", function()
        if BONUS_HINTS_UNDERSTOOD:GetBool() then return end

        CFCPvPWeapons.PlayHints( bonusHints )
    end )

    net.Receive( "CFC_PvPWeapons_BonkRifle_UnderstandBonusHints", function()
        BONUS_HINTS_UNDERSTOOD:SetBool( true )
    end )

    return
end

-- Call immediately before firing bullets.
-- Collects separate damage events together.
function SWEP:CollectBonkHits()
    CFCPvPWeapons.CollectBonkHits( self )
end

-- Call immediately after firing bullets, dealing damage, etc. If you delay by even one tick, it'll break things!
function SWEP:ApplyBonkHits()
    CFCPvPWeapons.ApplyBonkHits( self )
end

function SWEP:FireWeapon()
    local owner = self:GetOwner()
    if IsValid( owner ) and owner:IsPlayer()
        and not owner._cfcPvPWeapons_BonkRifle_BonusHintsUnderstood
        and owner:GetInfoNum( "cfc_pvp_weapons_bonk_rifle_bonus_hints_understood", 0 ) == 0 then
        local nextBonusHintTime = owner._cfcPvPWeapons_BonkRifle_NextBonusHintTime or 0

        if CurTime() >= nextBonusHintTime then
            owner._cfcPvPWeapons_BonkRifle_NextBonusHintTime = CurTime() + bonusHintCooldown

            timer.Simple( 0, function()
                if not IsValid( owner ) then return end
                if owner._cfcPvPWeapons_BonkRifle_BonusHintsUnderstood then return end
                if owner:GetInfoNum( "cfc_pvp_weapons_bonk_rifle_bonus_hints_understood", 0 ) == 1 then return end

                net.Start( "CFC_PvPWeapons_BonkRifle_PlayBonusHints" )
                net.Send( owner )
            end )
        end
    end

    local selfForce = self.Bonk.SelfForce
    if not selfForce then return BaseClass.FireWeapon( self ) end

    local ply = owner
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

    self:CollectBonkHits()
    BaseClass.FireWeapon( self )
    self:ApplyBonkHits()
end

hook.Add( "DoPlayerDeath", "CFC_PvPWeapons_BonkRifle_UnderstandBonusHints", function( victim, attacker, dmgInfo )
    if victim == attacker then return end
    if not IsValid( attacker ) or not attacker:IsPlayer() then return end
    if attacker:GetInfoNum( "cfc_pvp_weapons_bonk_rifle_bonus_hints_understood", 0 ) == 1 then return end

    local inflictor = dmgInfo:GetInflictor()
    if not IsValid( inflictor ) or inflictor:GetClass() ~= "cfc_bonk_rifle" then return end

    attacker._cfcPvPWeapons_BonkRifle_BonusHintsUnderstood = true

    net.Start( "CFC_PvPWeapons_BonkRifle_UnderstandBonusHints" )
    net.Send( attacker )
end )
