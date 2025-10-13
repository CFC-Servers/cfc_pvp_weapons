AddCSLuaFile()

DEFINE_BASECLASS( "cfc_simple_base" )
SWEP.Base = "cfc_simple_base"

-- UI stuff

SWEP.PrintName = "Gambler's Revolver"
SWEP.Category = "CFC"

SWEP.Slot = 1
SWEP.Spawnable = true

if CLIENT then
    CFCPvPWeapons.CL_SetWeaponSelectIcon( SWEP, "cfc_gamblers_revolver", "materials/vgui/hud/cfc_gamblers_revolver.png" )
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
    TracerFrequency = 1,
}

SWEP.ViewOffset = Vector( 0, 0, 0 ) -- Optional: Applies an offset to the viewmodel's position
SWEP.DropCleanupDelay = 15
SWEP.KillIconPrefix = "cfc_gamblers_revolver_rusty_"
SWEP.KillIconDefault = "regular"

SWEP.Secondary.ClipSize = 10

SWEP.CanPointAtSelf = true
SWEP.PointAtSelfDuration = 0.5
SWEP.PointAtSelfAwayDuration = 0.5
SWEP.PointAtSelfBoneManips = {
    ["ValveBiped.Bip01_R_UpperArm"] = Angle( 20, 50, 0 ),
    ["ValveBiped.Bip01_R_Forearm"] = Angle( 10, -50, 30 ),
    ["ValveBiped.Bip01_R_Hand"] = Angle( 0, -120, 0 ),
}

SWEP.CFCPvPWeapons_HitgroupNormalizeTo = { -- Make the head hitgrouip be the only one to scale damage.
    [HITGROUP_CHEST] = 1,
    [HITGROUP_STOMACH] = 1,
    [HITGROUP_LEFTARM] = 1,
    [HITGROUP_RIGHTARM] = 1,
    [HITGROUP_LEFTLEG] = 1,
    [HITGROUP_RIGHTLEG] = 1,
    [HITGROUP_GEAR] = 1,
}

SWEP.VMShake = {
    StrengthStart = 0.1,
    StrengthEnd = 0.5,
    StrengthEase = function( x ) return x end, -- Easing function to use for the viewmodel shake strength (linear by default)
    StrengthMovementBonus = 1.5 / 400, -- Multiplies the shake strength by 1 + ( the player's movespeed * this value ).
    IntervalMinStart = 0.075,
    IntervalMaxStart = 0.075,
    IntervalMinEnd = 0.01,
    IntervalMaxEnd = 0.075,
    Lerp = 1.5, -- How strongly to follow changes in the desired ViewOffset position, per second. 1 means it will reach the new position in 1 second, 2 in 0.5 seconds, etc.
}


CFCPvPWeapons.GamblersRevolver = CFCPvPWeapons.GamblersRevolver or {}
CFCPvPWeapons.GamblersRevolver.SCREENSHAKES = CFCPvPWeapons.GamblersRevolver.SCREENSHAKES or {}
CFCPvPWeapons.GamblersRevolver.SOUNDS = CFCPvPWeapons.GamblersRevolver.SOUNDS or {}

local ANGLE_ZERO = Angle( 0, 0, 0 )

local SCREENSHAKES = CFCPvPWeapons.GamblersRevolver.SCREENSHAKES
table.Merge( CFCPvPWeapons.GamblersRevolver.SCREENSHAKES, {
    LUCKY = {
        Near = { Amplitude = 5, Frequency = 40, Duration = 0.3, Radius = 100, AirShake = true, },
        Far = { Amplitude = 5, Frequency = 40, Duration = 0.3, Radius = 250, AirShake = true, },
    },
    SUPERLUCKY = {
        Near = { Amplitude = 10, Frequency = 40, Duration = 1, Radius = 100, AirShake = true, },
        Far = { Amplitude = 10, Frequency = 40, Duration = 1, Radius = 350, AirShake = true, },
    },
    UNHOLY = {
        Near = { Amplitude = 10, Frequency = 40, Duration = 2, Radius = 100, AirShake = true, },
        Far = { Amplitude = 15, Frequency = 40, Duration = 2, Radius = 500, AirShake = true, },
    },
} )

local SOUNDS = CFCPvPWeapons.GamblersRevolver.SOUNDS
table.Merge( CFCPvPWeapons.GamblersRevolver.SOUNDS, {
    LUCKY = {
        { Path = "weapons/357/357_fire2.wav", Pitch = 75, Channel = CHAN_STATIC, },
    },
    SUPERLUCKY = {
        { Path = "weapons/ar2/npc_ar2_altfire.wav", Pitch = 100, Channel = CHAN_STATIC, },
        { Path = "weapons/physcannon/superphys_launch1.wav", Pitch = 100, Channel = CHAN_STATIC, },
    },
    UNHOLY = {
        { Path = "weapons/mortar/mortar_explode2.wav", Pitch = 40, Channel = CHAN_AUTO, },
        { Path = "weapons/physcannon/superphys_launch1.wav", Pitch = 40, Channel = CHAN_STATIC, },
        { Path = "weapons/crossbow/bolt_skewer1.wav", Pitch = 40, Channel = CHAN_STATIC, },
    },

    ROULETTE_EMPTY = {
        { Path = "weapons/pistol/pistol_empty.wav", Pitch = 100, Channel = CHAN_STATIC, },
    },
    ROULETTE_LOSE = {
        { Path = SWEP.Primary.Sound, Pitch = 100, Channel = CHAN_WEAPON, },
    },
    ROULETTE_WIN = {
        { Path = "buttons/button4.wav", Pitch = 135, Channel = CHAN_AUTO, },
    },
} )


function SWEP:Initialize()
    BaseClass.Initialize( self )

    -- Can't add to the SWEP table normally, as child classes with fewer entries will have some of these forcibly added in.
    self.Primary.DamageDice = {
        { Damage = 10, Weight = 60, },
        { Damage = 20, Weight = 100, },
        { Damage = 30, Weight = 60, },
        { Damage = 125, Weight = 16, KillIcon = "lucky", Sounds = SOUNDS.LUCKY, Group = "crit", Screenshake = SCREENSHAKES.LUCKY, Tracer = "GaussTracer", },
        { Damage = 5000, Weight = 2, KillIcon = "superlucky", Sounds = SOUNDS.SUPERLUCKY, Group = "crit", HullSize = 1, Screenshake = SCREENSHAKES.SUPERLUCKY, Tracer = "GaussTracer", },
        { Damage = 0, Weight = 3, KillIcon = "unlucky", Sounds = SOUNDS.UNHOLY, SelfDamage = 100000, SelfForce = 5000, BehindDamage = 150, BehindHullSize = 10, DropWeapon = true, },
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
        { Weight = 3, Sounds = SOUNDS.ROULETTE_EMPTY, },
        { Weight = 1, SelfDamage = 1000, KillIcon = "self", Sounds = SOUNDS.ROULETTE_LOSE, DropWeapon = true, },
        { Weight = 2, Sounds = SOUNDS.ROULETTE_WIN, Function = function( wep )
            -- Give a guaranteed crit on the next non-self shot.
            wep:SetCritsLeft( wep:GetCritsLeft() + 1 )
        end },
    }
    table.SortByMember( self.Primary.PointAtSelfOutcomes, "Weight", false )

    self:SetFirstTimeHints()

    if CLIENT then
        self:SetUpVMShake()
    end
end

function SWEP:SetFirstTimeHints()
    self.CFC_FirstTimeHints = {
        {
            Message = "The Gambler's Revolver has a chance to deal critical hits for massive damage.",
            Sound = "ambient/water/drip1.wav",
            Duration = 10,
            DelayNext = 6,
        },
        {
            Message = "Hold right click to play Russian Roulette for a higher chance at guaranteed crits.",
            Sound = "ambient/water/drip2.wav",
            Duration = 10,
            DelayNext = 7,
        },
        {
            Message = "Guaranteed crits are tracked in your secondary ammo counter.",
            Sound = "ambient/water/drip1.wav",
            Duration = 10,
            DelayNext = 0,
        },
    }
end

function SWEP:GetDamageDiceFilter()
    if self:GetCritsLeft() > 0 then
        return function( dice ) return dice.Group == "crit" end
    end
end

function SWEP:SetCritsLeft( amount )
    self:SetClip2( math.Clamp( amount, 0, self:GetMaxClip2() ) )
end

function SWEP:GetCritsLeft()
    return self:Clip2()
end

-- Applies a damage dice outcome, auto-handling various fields. bullet is optional, though required for Damage or Force.
-- If bullet is provided and Damage is zero, that bullet will be marked with DontShoot.
-- Screenshake will apply Near on the owner and Far on where the main bullet hits, if applicable.
function SWEP:ApplyDamageDice( outcome, bullet )
    local owner = self:GetOwner()

    self._cfcPvPWeapons_KillIcon = self.KillIconPrefix .. ( outcome.KillIcon or self.KillIconDefault )
    self:DamageDiceHandleBullet( outcome, bullet )
    self:DamageDiceHandleTracer( outcome, bullet )

    if SERVER and outcome.Screenshake and outcome.Screenshake.Near then
        local shake = outcome.Screenshake.Near
        util.ScreenShake( owner:GetShootPos(), shake.Amplitude, shake.Frequency, shake.Duration, shake.Radius, shake.AirShake )
    end

    if outcome.BehindDamage then
        local behindBullet = {
            Num = 1,
            Src = owner:GetShootPos(),
            Dir = -owner:GetAimVector(),
            TracerName = self.Primary.TracerName,
            Tracer = self.Primary.TracerName == "" and 0 or self.Primary.TracerFrequency,
            Force = outcome.BehindForce or ( outcome.BehindDamage * 0.25 ),
            Damage = outcome.BehindDamage,
            HullSize = outcome.BehindHullSize,
            Callback = function( _attacker, tr, dmg )
                dmg:ScaleDamage( self:GetDamageFalloff( tr.StartPos:Distance( tr.HitPos ) ) )
            end,
        }
        owner:FireBullets( behindBullet )
    end

    if SERVER and outcome.DropWeapon then
        owner:DropWeapon( self, nil, owner:GetAimVector() * 400 )
    end

    if SERVER and outcome.SelfDamage then
        CFCPvPWeapons.DealSelfDamage( self, outcome.SelfDamage, outcome.SelfForce, -owner:GetAimVector(), DMG_BULLET, owner )
    end

    if outcome.Sounds then
        for _, sndInfo in ipairs( outcome.Sounds ) do
            self:EmitSound( sndInfo.Path, sndInfo.SoundLevel or 85, sndInfo.Pitch or 100, sndInfo.Volume or 1, sndInfo.Channel or CHAN_AUTO )
        end
    end

    if outcome.Function then
        outcome.Function( self, outcome, bullet )
    end
end

-- Pulled out of :ApplyDamageDice() for readability.
function SWEP:DamageDiceHandleBullet( outcome, bullet )
    if not bullet then return end

    bullet.Damage = outcome.Damage or bullet.Damage
    bullet.Force = outcome.Force or ( bullet.Damage * 0.25 )
    bullet.HullSize = outcome.HullSize or bullet.HullSize -- Note that HullSize > 1 will allow any intersection with the player collision hull to count, not just their damage hitboxes!
    bullet.TracerName = outcome.Tracer or bullet.TracerName

    -- Allow the bullet to be disabled, to allow BehindDamage to be the only bullet, or to make the engine not
    --   get confused when SelfDamage kills the owner and the normal bullet tries to fire afterwards.
    -- (Such a case causes the game to treat it like a regular .357 shot, damage and killicon and all.)
    if bullet.Damage == 0 then
        bullet.DontShoot = true
    end

    local screenshake = outcome.Screenshake

    if SERVER and screenshake and screenshake.Far then
        local cb = bullet.Callback or function() end
        local shake = screenshake.Far

        bullet.Callback = function( attacker, tr, dmg )
            cb( attacker, tr, dmg )
            util.ScreenShake( tr.HitPos, shake.Amplitude, shake.Frequency, shake.Duration, shake.Radius, shake.AirShake )
        end
    end
end

-- Pulled out of :ApplyDamageDice() for readability.
function SWEP:DamageDiceHandleTracer( outcome, bullet )
    if not bullet then return end
    if not outcome.Tracer then return end
    if CLIENT and not IsFirstTimePredicted() then return end

    local cb = bullet.Callback or function() end
    local owner = self:GetOwner()

    -- Some tracer effects (e.g. GaussTracer) don't work with the bullet system and need to be done manually.
    bullet.Tracer = 0
    bullet.Callback = function( attacker, tr, dmg )
        cb( attacker, tr, dmg )

        local rf

        if SERVER then
            rf = RecipientFilter()
            rf:AddAllPlayers()
            rf:RemovePlayer( owner ) -- Owner is doing it already on their end, don't double up.
        end

        local eff = EffectData()
        local useViewModel = CLIENT and not owner:ShouldDrawLocalPlayer()
        local attachEnt = useViewModel and owner:GetViewModel() or owner
        local attachID = attachEnt:LookupAttachment( useViewModel and "muzzle" or "anim_attachment_RH" )

        if attachID > 0 then
            eff:SetStart( attachEnt:GetAttachment( attachID ).Pos )
        else
            eff:SetStart( tr.StartPos )
        end

        eff:SetOrigin( tr.HitPos )
        eff:SetEntity( owner )
        eff:SetScale( 10000 )
        eff:SetFlags( 0 )
        util.Effect( outcome.Tracer, eff, nil, rf )
    end
end

function SWEP:ModifyBulletTable( bullet )
    local outcomes = self.Primary.DamageDice
    local outcome = CFCPvPWeapons.GetWeightedOutcome( outcomes, self:GetDamageDiceFilter(), "cfc_gamblers_revolver_damagedice" ) or outcomes[1]

    if self:GetCritsLeft() > 0 then
        self:SetCritsLeft( self:GetCritsLeft() - 1 )
    end

    self:ApplyDamageDice( outcome, bullet )
end

function SWEP:UnholyBlast( outcome, bullet )
    local cb = bullet.Callback or function() end
    bullet.Callback = function( attacker, tr, dmgInfo )
        cb( attacker, tr, dmgInfo )
        if not IsValid( self ) then return end

        timer.Simple( 0, function()
            if not IsValid( self ) then return end
            if not IsValid( attacker ) then return end

            local pos = tr.HitPos + tr.HitNormal * 10

            local eff = EffectData()
            eff:SetScale( 100 )
            eff:SetMagnitude( 100 )
            eff:SetFlags( 4 )

            for _ = 1, 20 do
                eff:SetOrigin( pos + VectorRand() * 150 )
                util.Effect( "Explosion", eff, true, true )
            end

            local blastInfo = DamageInfo()
            blastInfo:SetAttacker( attacker )
            blastInfo:SetInflictor( self )
            blastInfo:SetDamage( outcome.Damage )
            blastInfo:SetDamageType( DMG_DISSOLVE )
            util.BlastDamageInfo( blastInfo, pos, 300 )
        end )
    end
end

function SWEP:CFCPvPWeapons_GetKillIcon()
    return self._cfcPvPWeapons_KillIcon
end

function SWEP:Deploy()
    self._cfcPvPWeapons_PointingAtSelf = false
    self._cfcPvPWeapons_PointingAtSelfChanging = false

    return BaseClass.Deploy( self )
end

function SWEP:Holster()
    self:ResetPointAtSelfBoneManips( self:GetOwner() )

    if CLIENT then
        self:ResetVMShake( false )
    end

    return BaseClass.Holster( self )
end

function SWEP:OnDrop( owner )
    self:ResetPointAtSelfBoneManips( owner )
    self:SetCritsLeft( 0 )

    return BaseClass.OnDrop( self, owner )
end

function SWEP:OnRemove()
    self:ResetPointAtSelfBoneManips( self:GetOwner() )

    return BaseClass.OnRemove( self )
end

function SWEP:CanReload()
    if self.CanPointAtSelf then
        local notPointingAway = self:IsPointingAtSelfChanging() or self:IsPointingAtSelf()
        if notPointingAway then return false end
    end

    return BaseClass.CanReload( self )
end

function SWEP:CanPrimaryFire()
    if self.CanPointAtSelf and self:IsPointingAtSelfChanging() then return false end

    return BaseClass.CanPrimaryFire( self )
end

function SWEP:PrimaryFire()
    if self.CanPointAtSelf and self:IsPointingAtSelf() then
        return self:PrimaryFireAtSelf()
    end

    return BaseClass.PrimaryFire( self )
end

function SWEP:PrimaryFireAtSelf()
    self:SetNextFire( CurTime() + self:GetDelay() )
    self:ConsumeAmmo()

    local outcome = CFCPvPWeapons.GetWeightedOutcome( self.Primary.PointAtSelfOutcomes, nil, "cfc_gamblers_revolver_fireatself" ) or self.Primary.PointAtSelfOutcomes[1]

    if outcome.SelfDamage then
        self:SendWeaponAnim( ACT_VM_PULLBACK_HIGH )
    end

    self:ApplyDamageDice( outcome )
end

function SWEP:IsPointingAtSelf()
    return self._cfcPvPWeapons_PointingAtSelf or false
end

function SWEP:IsPointingAtSelfChanging()
    return self._cfcPvPWeapons_PointingAtSelfChanging or false
end

function SWEP:OnPointAtSelfChanged( pointingAtSelf )
    if CLIENT then
        self:ResetVMShake( pointingAtSelf ) -- Shake the viewmodel while pointing at self.
    end
end

function SWEP:PointAtSelfThink()
    if not self.CanPointAtSelf then return end

    local owner = self:GetOwner()
    if not IsValid( owner ) then return end -- Shouldn't happen due to :Think() limits, but just in case.

    -- If we're changing states...
    if self._cfcPvPWeapons_PointingAtSelfChanging then
        -- Finish the change.
        if CurTime() >= self._cfcPvPWeapons_PointAtSelfChangeTime then
            local newState = not self._cfcPvPWeapons_PointingAtSelf

            self._cfcPvPWeapons_PointingAtSelf = newState
            self._cfcPvPWeapons_PointingAtSelfChanging = false

            if newState then
                self:ApplyPointAtSelfBoneManips( owner )
            else
                self:ResetPointAtSelfBoneManips( owner )
                self:SendWeaponAnim( ACT_VM_IDLE )
            end

            self:OnPointAtSelfChanged( newState )
        end

        return -- Still changing, keep waiting.
    end

    -- Not currently changing states, see if the owner wants to change.
    if self:IsReloading() then return end -- Can't change while reloading.

    local curState = self._cfcPvPWeapons_PointingAtSelf or false
    local targetState = owner:KeyDown( IN_ATTACK2 ) -- Point at self while holding RMB (animation delays permitting)
    if curState == targetState then return end -- Already in the desired state, do nothing.

    -- Start changing states.
    self._cfcPvPWeapons_PointingAtSelfChanging = true
    self._cfcPvPWeapons_PointAtSelfChangeTime = CurTime() + ( targetState and self.PointAtSelfDuration or self.PointAtSelfAwayDuration )
    self:SendWeaponAnim( targetState and ACT_VM_PULLBACK or ACT_VM_PULLBACK_LOW )
    self:SetNextIdle( 0 )

    if CLIENT then
        self:ResetVMShake( false )
    end
end

function SWEP:Think()
    BaseClass.Think( self )
    self:PointAtSelfThink()

    if self:GetCritsLeft() > 0 then
        self.RenderGroup = RENDERGROUP_TRANSLUCENT
    else
        self.RenderGroup = RENDERGROUP_OPAQUE
    end

    if CLIENT then
        self:VMShakeThink()
    end
end

function SWEP:ResetPointAtSelfBoneManips( owner )
    if not self.CanPointAtSelf then return end
    if not IsValid( owner ) then return end

    for boneName in pairs( self.PointAtSelfBoneManips ) do
        local boneIndex = owner:LookupBone( boneName )
        if boneIndex then
            owner:ManipulateBoneAngles( boneIndex, ANGLE_ZERO )
        end
    end
end

function SWEP:ApplyPointAtSelfBoneManips( owner )
    if not self.CanPointAtSelf then return end
    if not IsValid( owner ) then return end

    for boneName, ang in pairs( self.PointAtSelfBoneManips ) do
        local boneIndex = owner:LookupBone( boneName )
        if boneIndex then
            owner:ManipulateBoneAngles( boneIndex, ang )
        end
    end
end


if CLIENT then
    function SWEP:CustomAmmoDisplay()
        return {
            Draw = true,
            PrimaryClip = self:Clip1(),
            PrimaryAmmo = self:GetOwner():GetAmmoCount( self.Primary.Ammo ),
            SecondaryAmmo = self:GetCritsLeft() > 0 and self:GetCritsLeft() or nil,
        }
    end


    local critSpriteMat = Material( "sprites/redglow1" )
    local critSpriteColor = Color( 255, 50, 50 )
    local critSpriteOffset = Vector( 10, 0, -4 )
    local critSpriteSize = 48


    function SWEP:DrawCritSprite()
        if self:GetCritsLeft() < 1 then return end

        local owner = self:GetOwner()
        if not IsValid( owner ) then return end

        local boneID = owner:LookupBone( "ValveBiped.Bip01_R_Hand" ) -- Right Hand
        if not boneID then return end

        local matrix = owner:GetBoneMatrix( boneID )
        if not matrix then return end

        local pos = LocalToWorld( critSpriteOffset, ANGLE_ZERO, matrix:GetTranslation(), matrix:GetAngles() )

        render.SetMaterial( critSpriteMat )
        render.DrawSprite( pos, critSpriteSize, critSpriteSize, critSpriteColor )
    end

    function SWEP:DrawWorldModelTranslucent( flags )
        self:DrawCritSprite()

        return BaseClass.DrawWorldModelTranslucent( self, flags )
    end

    function SWEP:SetUpVMShake()
        local baseViewOffset = self.ViewOffset

        self._baseViewOffset = baseViewOffset
        self._targetViewOffset = Vector( baseViewOffset[1], baseViewOffset[2], baseViewOffset[3] )
        self._nextViewOffsetChange = 0
        self._isVMShakeActive = false
        self._isVMShakeLerpMatched = false
    end

    function SWEP:VMShakeThink()
        if not self._isVMShakeActive then return end

        self:VMShakeChange()

        if self._isVMShakeLerpMatched then return end

        local viewOffset = self.ViewOffset
        local targetOffset = self._targetViewOffset

        if viewOffset:Distance( targetOffset ) < 0.01 then
            self.ViewOffset = targetOffset
            self._isVMShakeLerpMatched = true
        else
            self.ViewOffset = LerpVector( FrameTime() * self.VMShake.Lerp, viewOffset, targetOffset )
        end
    end

    function SWEP:VMShakeChange()
        local nextChangeTime = self._nextViewOffsetChange
        local now = CurTime()

        if now >= nextChangeTime then
            -- Stronger the fewer bullets there are in the clip.
            local clipMax = self.Primary.ClipSize
            local frac = self.VMShake.StrengthEase( ( clipMax - math.min( self:Clip1(), clipMax ) ) / clipMax )

            local shakeStrength = Lerp( frac, self.VMShake.StrengthStart, self.VMShake.StrengthEnd )
            local speedBonus = self.VMShake.StrengthMovementBonus
            local interval = math.Rand(
                Lerp( frac, self.VMShake.IntervalMinStart, self.VMShake.IntervalMinEnd ),
                Lerp( frac, self.VMShake.IntervalMaxStart, self.VMShake.IntervalMaxEnd )
            )

            if speedBonus ~= 0 then
                shakeStrength = shakeStrength * ( LocalPlayer():GetVelocity():Length() * speedBonus + 1 )
            end

            self._nextViewOffsetChange = now + interval
            self._targetViewOffset = self._baseViewOffset + Vector( math.Rand( -shakeStrength, shakeStrength ), math.Rand( -shakeStrength, shakeStrength ), math.Rand( -shakeStrength, shakeStrength ) )
            self._isVMShakeLerpMatched = false
        end
    end

    function SWEP:ResetVMShake( active )
        self.ViewOffset = self._baseViewOffset
        self._isVMShakeActive = active
    end
end
