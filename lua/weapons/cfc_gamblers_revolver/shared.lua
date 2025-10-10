AddCSLuaFile()

DEFINE_BASECLASS( "cfc_simple_base" )
SWEP.Base = "cfc_simple_base"

-- UI stuff

SWEP.PrintName = "Gambler's Revolver"
SWEP.Category = "CFC"

SWEP.Slot = 1
SWEP.Spawnable = true

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
    Ammo = "357", -- The ammo type used when reloading
    Cost = 1, -- The amount of ammo used per shot

    ClipSize = 6, -- The amount of ammo per magazine, -1 to have no magazine (pull from reserves directly)
    DefaultClip = 1000, -- How many rounds the player gets when picking up the weapon for the first time, excess ammo will be added to the player's reserves

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
SWEP.KillIconPrefix = "cfc_gamblers_revolver_rusty_"
SWEP.KillIconDefault = "regular"


function SWEP:Initialize()
    BaseClass.Initialize( self )

    -- Can't add to the SWEP table normally, as child classes with fewer entries will have some of these forcibly added in.
    self.Primary.DamageDice = {
        { Damage = 10, Weight = 60, },
        { Damage = 20, Weight = 100, },
        { Damage = 30, Weight = 60, },
        { Damage = 125, Weight = 15, KillIcon = "lucky", Sound = "physics/glass/glass_impact_bullet4.wav", },
        { Damage = 1000, Weight = 2, KillIcon = "superlucky", Sound = "physics/glass/glass_largesheet_break1.wav", },
        { Damage = 0, Weight = 3, KillIcon = "unlucky", Sound = "npc/manhack/gib.wav", SoundPitch = 130, SelfDamage = 1000, SelfForce = 5000, },
    }

    table.SortByMember( self.Primary.DamageDice, "Weight", false )
end

function SWEP:ModifyBulletTable( bullet )
    -- No need for the client to predict the damage roll.
    -- Better, in fact, as not using commandnum for the seed means clients can't force high rolls.
    if CLIENT then return end

    local damageDice = self.Primary.DamageDice
    local totalWeight = 0

    for _, dice in ipairs( damageDice ) do
        totalWeight = totalWeight + dice.Weight
        dice._weightAccum = totalWeight
    end

    local damageRoll = math.Rand( 0, totalWeight )
    local diceChoice = damageDice[1]
    local owner = self:GetOwner()

    for _, dice in ipairs( damageDice ) do
        if damageRoll <= dice._weightAccum then
            diceChoice = dice

            break
        end
    end

    if diceChoice.Sound and diceChoice.Sound ~= "" then
        local rf = RecipientFilter()
        rf:AddPAS( self:GetPos() )
        rf:AddPlayer( owner )

        owner:EmitSound( diceChoice.Sound, 85, diceChoice.SoundPitch or 100, 1, CHAN_AUTO, nil, nil, rf )
    end

    bullet.Damage = diceChoice.Damage
    bullet.Force = diceChoice.Force or ( bullet.Damage * 0.25 )
    self._cfcPvPWeapons_KillIcon = self.KillIconPrefix .. ( diceChoice.KillIcon or self.KillIconDefault )

    if diceChoice.SelfDamage then
        local dirBack = -bullet.Dir
        local dmgInfo = DamageInfo()
        dmgInfo:SetDamage( diceChoice.SelfDamage )
        dmgInfo:SetAttacker( game.GetWorld() )
        dmgInfo:SetInflictor( self )
        dmgInfo:SetDamageType( DMG_BULLET )
        dmgInfo:SetDamageForce( dirBack * ( diceChoice.SelfForce or ( diceChoice.SelfDamage * 0.25 ) ) )
        owner:TakeDamageInfo( dmgInfo )

        bullet.Dir = dirBack
    end

    if diceChoice.Function then
        diceChoice.Function( self, bullet )
    end
end

function SWEP:CFCPvPWeapons_GetKillIcon()
    return self._cfcPvPWeapons_KillIcon
end
