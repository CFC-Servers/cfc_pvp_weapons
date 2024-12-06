AddCSLuaFile()

DEFINE_BASECLASS( "cfc_charge_gun_base" )

SWEP.Base = "cfc_charge_gun_base"

-- UI stuff

SWEP.PrintName = "Graviton Gun"
SWEP.Category = "CFC"

SWEP.DrawWeaponInfoBox = true
SWEP.Author = "CFC"
SWEP.Contact = "cfc.gg/discord"
SWEP.Purpose = "Anti-propfly gun"
SWEP.Instructions = "Shoot prop fliers out of the air\nCharge up for a bigger firing cone"

SWEP.Slot = 4
SWEP.Spawnable = true

-- Appearance

SWEP.UseHands = true -- If your viewmodel includes its own hands (v_ model instead of a c_ model), set this to false

SWEP.ViewModelTargetFOV = 54 -- The default viewmodel FOV, SWEP.ViewModelFOV gets overwritten by the base itself

SWEP.ViewModel = Model( "models/weapons/cfc_graviton_gun/c_physcannon.mdl" ) -- Weapon viewmodel, usually a c_ or v_ model
SWEP.WorldModel = Model( "models/weapons/cfc_graviton_gun/w_physics.mdl" ) -- Weapon worldmodel, almost always a w_ model

SWEP.HoldType = "physgun" -- Default holdtype, you can find all the options here: https://wiki.facepunch.com/gmod/Hold_Types
SWEP.CustomHoldType = {} -- Allows you to override any hold type animations with your own, uses [ACT_MP_STAND_IDLE] = ACT_HL2MP_IDLE_SHOTGUN formatting

-- Weapon stats

SWEP.Firemode = 0 -- The default firemode, -1 = full-auto, 0 = semi-auto, >1 = burst fire

SWEP.Primary = {
    Ammo = "AR2", -- The ammo type used when reloading. Set to an empty string to not need/use/show ammo
    Cost = 1, -- The amount of ammo used per shot

    ClipSize = 50, -- The max ammount of ammo for a full charge
    DefaultClip = 1000, -- How many rounds the player gets when picking up the weapon for the first time, excess ammo will be added to the player's reserves

    Damage = 10, -- Damage per shot

    Delay = 2 / 50, -- Delay between each buildup of charge, use 60 / x for RPM (Rounds per minute) values
    BurstEnabled = false, -- When releasing the charge, decides whether to burst-fire the weapon once per unit ammo, or to expend the full charge in one fire call
    BurstDelay = 0.075, -- Burst only: the delay between shots during a burst
    Cooldown = 3, -- Cooldown to apply once the charge is expended
    MovementMultWhenCharging = 0.75, -- Multiplier against movement speed when charging
    OverchargeDelay = 4, -- Once at full charge, it takes this long before overcharge occurs. False to disable overcharge.
    OverchargeKnockback = 1000, -- Overcharging blasts the player up and backwards with this much speed.
    OverchargeExplosionDamage = 30, -- Damage dealt by the overcharge explosion.
    OverchargeExplosionRadius = 150, -- Radius of the overcharge explosion.

    Recoil = {
        MinAng = Angle( 0.5, -2, 0 ), -- The minimum amount of recoil punch per shot
        MaxAng = Angle( 2, 2, 0 ), -- The maximum amount of recoil punch per shot
        Punch = 0.2, -- The percentage of recoil added to the player's view angles, if set to 0 a player's view will always reset to the exact point they were aiming at
        Ratio = 0.4 -- The percentage of recoil that's translated into the viewmodel, higher values cause bullets to end up above the crosshair
    },
    RecoilCharging = {
        Mult = 0.01, -- If above zero, will repeatedly apply recoil while charging, with this as a strength multiplier. Scales with charge level.
        MinAng = Angle( -20, -10, 0 ),
        MaxAng = Angle( 20, 10, 0 ),
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

    ChargeSound = "npc/combine_gunship/engine_whine_loop1.wav", -- Should be a looping sound
    ChargeVolume = 0.5,
    ChargeStepSound = "",
    ChargeStepVolume = 1,
    ChargeStepPitchMinStart = 100,
    ChargeStepPitchMaxStart = 100,
    ChargeStepPitchMinEnd = 255,
    ChargeStepPitchMaxEnd = 255,
    ChargeStepPitchEase = function( x ) return x end, -- Use an easing function (e.g. math.ease.InCubic). Default is linear, which isn't in the ease library.

    ChargeSprite = {
        Enabled = true,
        Mat = "sprites/light_glow01", -- Material path for the sprite (should have ignorez)
        MatVM = "cfc_pvp_weapons/sprites/charge_glow", -- Material path for the viewmodel (shouldn't have ignorez)
        Offset = Vector( 27, 0, 5 ), -- Position offset for the sprite
        OffsetVM = Vector( 32, -4, -4 ), -- Position offset for the viewmodel sprite
        Color = Color( 255, 150, 80 ),
        AlphaStart = 0,
        AlphaEnd = 255,
        Framerate = 10,
        ScaleStart = 0.5, -- Used by the world sprite
        ScaleEnd = 1.25, -- Used by the world sprite
        SizeStart = 10, -- Used by the viewmodel sprite
        SizeEnd = 20, -- Used by the viewmodel sprite
    },

    -- Graviton Gun settings:
    GravitonAimConeMin = 2, -- The minimum total width of the aim cone, in degrees. The effective cone scales based on charge.
    GravitonAimConeMax = 20, -- The maximum total width of the aim cone, in degrees. The effective cone scales based on charge.

    GravitonMaxRange = 15000, -- The maximum range of the graviton beam.
    GravitonHeightThreshold = 100, -- If the victim is too close to the ground, don't hit them.
    GravitonStackMult = 1, -- If the victim already has a graviton effect, multiply its acceleration by this much before adding the new effect to it.
    GravitonHorizontalToDownwards = { -- Convert some of the victim's initial horizontal velocity to downwards velocity. Different factors for different distances.
        { dist = 0, factor = 0.75, },
        { dist = 3000, factor = 0.5, },
        { dist = 7000, factor = 0.3, },
        { dist = 12000, factor = 0.15, },
    },

    GravitonDropProp = true, -- If the victim is physguning a prop, drop it.
    GravitonDropPropKnockback = 1000, -- If a physgunned prop is dropped by the graviton gun, how much velocity to use to push it away from the victim.

    GravitonAccelerationMult = 0.75, -- Take a portion of the victim's initial horizontal velocity and apply it as a downwards acceleration on top of normal gravity.
    GravitonAccelerationAdd = 300, -- Flat bonus acceleration to apply downwards.

    GravitonFallDamageDiv = 1900, -- Divides fall speed before going into the ease func.
    GravitonFallDamageEase = math.ease.InQuart, -- Easing function to apply to fall damage.
    GravitonFallDamageMult = 80, -- Multiplies fall damage after ease func.
    GravitonFallDamageSpeedThreshdold = 1200, -- Speed at which fall damage starts to be applied.

    GravitonTrailInterval = 0.1,
    GravitonTrailLength = 2,
    GravitonTrailSpeed = 1,
    GravitonTrailOffsetSpread = 30,
    GravitonTrailAmount = 5,

    GravitonBeamWidth = 30,
    GravitonBeamDuration = 2,
    GravitonBeamColor = Color( 255, 150, 80 ),

    -- Superseeded by charge base or graviton gun, leave as-is:
    Count = 1, -- Optional: Shots fired per shot
    PumpAction = false, -- Optional: Tries to pump the weapon between shots
    PumpSound = "Weapon_Shotgun.Special1", -- Optional: Sound to play when pumping
    Range = 750,
    Accuracy = 12,
    UnscopedRange = 0,
    UnscopedAccuracy = 0,
    RangeModifier = 0.85,
    Sound = "Weapon_Pistol.Single",
    TracerName = "Tracer",
}

SWEP.ViewOffset = Vector( 0, 0, 0 ) -- Optional: Applies an offset to the viewmodel's position

-- Scope base exclusive variables
SWEP.ScopeZoom = 1 -- A number (or table) containing the zoom levels the weapon can cycle through
SWEP.ScopeSound = "Default.Zoom" -- optional: Sound to play when cycling through zoom levels

SWEP.UseScope = false -- Whether this weapon obeys the draw scopes option
SWEP.HideInScope = true -- Whether the viewmodel should be hidden when a scope is being drawn

SWEP.CFC_FirstTimeHints = {
    {
        Message = "The Graviton Gun is a charged weapon. Hold left mouse before releasing to fire.",
        Sound = "ambient/water/drip1.wav",
        Duration = 8,
        DelayNext = 5,
    },
    {
        Message = "The Graviton Gun is great for taking down propsurfers and other airborne, non-vehicle targets.",
        Sound = "ambient/water/drip2.wav",
        Duration = 8,
        DelayNext = 0,
    },
}

local bonusHintCooldown = 8
local bonusHints = {
    {
        Message = "The Graviton Gun only works on airborne targets. Try shooting someone high in the air.",
        Sound = "ambient/water/drip1.wav",
        Duration = 8,
        DelayNext = 0,
    },
}


local GRAVITON_STATUS_LOOP_SOUND = "ambient/machines/city_ventpump_loop1.wav"

local physgunProps = {}
local gravitonBeamMat = CLIENT and Material( "sprites/physbeama" )
local BONUS_HINTS_UNDERSTOOD


if SERVER then
    util.AddNetworkString( "CFC_PvPWeapons_GravitonGun_PlayBonusHints" )
    util.AddNetworkString( "CFC_PvPWeapons_GravitonGun_UnderstandBonusHints" )
    util.AddNetworkString( "CFC_PvPWeapons_GravitonGun_MakeBeam" )
else
    BONUS_HINTS_UNDERSTOOD = CreateClientConVar( "cfc_pvp_weapons_graviton_gun_bonus_hints_understood", "0", true, true, "", 0, 1 )
end


function SWEP:GetGravitonAimCone( charge )
    local primary = self.Primary
    local minCone = primary.GravitonAimConeMin
    local maxCone = primary.GravitonAimConeMax

    return Lerp( charge / primary.ClipSize, minCone, maxCone )
end

function SWEP:FireWeapon( charge )
    local owner = self:GetOwner()
    local primary = self.Primary

    charge = math.min( charge, primary.ClipSize ) -- Just in case something forces a larger charge than the clip size (e.g. CFC Ammo powerup)

    if SERVER then
        local initialDamage = self:GetDamage()
        local maxRange = primary.GravitonMaxRange
        local shootPos = owner:GetShootPos()
        local shootDir = self:GetShootDir()
        local selfObj = self

        local hitATarget = false

        hook.Add( "PostEntityTakeDamage", "CFC_PvPWeapons_GravitonGun_DetectHit", function( victim, dmgInfo, took )
            if not took then return end
            if dmgInfo:GetInflictor() ~= selfObj then return end
            if not victim:IsPlayer() then return end

            hitATarget = true

            selfObj:DoGravitonHit( owner, victim )
        end )

        local aimCone = self:GetGravitonAimCone( charge )
        local dotThreshold = math.cos( math.rad( aimCone / 2 ) )
        local world = game.GetWorld()

        owner:LagCompensation( true )

        for _, ply in player.Iterator() do
            if ply == owner then continue end
            if not ply:Alive() then continue end
            if ply:InVehicle() then continue end
            if ply:WaterLevel() > 0 then continue end

            local groundEnt = ply:GetGroundEntity()
            if groundEnt == world then continue end
            if IsValid( groundEnt ) and not groundEnt:IsPlayerHolding() then continue end

            local plyPos = ply:GetPos()
            local plyCenter = plyPos + ply:OBBCenter()
            local toPly = plyCenter - shootPos
            local toPlyLength = toPly:Length()

            if toPlyLength == 0 then continue end
            if toPlyLength > maxRange then continue end

            local toPlyDir = toPly / toPlyLength
            local dot = shootDir:Dot( toPlyDir )
            if dot < dotThreshold then continue end

            local trace = util.TraceLine( {
                start = shootPos,
                endpos = plyCenter,
                filter = { owner, physgunProps[ply] },
                mask = MASK_SHOT,
            } )

            if trace.Hit and trace.Entity ~= ply then continue end

            local hullRadius = ply:OBBMaxs()[1]
            local groundTrace = util.TraceHull( {
                start = plyPos,
                endpos = plyPos - Vector( 0, 0, primary.GravitonHeightThreshold ),
                mins = Vector( -hullRadius, -hullRadius, 0 ),
                maxs = Vector( hullRadius, hullRadius, 0 ),
                filter = function( ent )
                    if ent == ply then return false end
                    if ent == world then return true end
                    if not IsValid( ent ) then return false end
                    if ent:IsPlayerHolding() then return false end
                    if ent:IsWeapon() then return false end

                    local physObj = ent:GetPhysicsObject()
                    if not IsValid( physObj ) then return false end
                    if physObj:IsMotionEnabled() then return false end

                    return true
                end,
            } )

            if groundTrace.Hit then continue end

            local dmgInfo = DamageInfo()
            dmgInfo:SetAttacker( owner )
            dmgInfo:SetInflictor( self )
            dmgInfo:SetDamage( initialDamage )
            dmgInfo:SetDamageType( DMG_ENERGYBEAM + DMG_PREVENT_PHYSICS_FORCE )
            dmgInfo:SetDamagePosition( plyCenter )

            ply:TakeDamageInfo( dmgInfo )
        end

        owner:LagCompensation( false )

        hook.Remove( "PostEntityTakeDamage", "CFC_PvPWeapons_GravitonGun_DetectHit" )


        local rf = RecipientFilter()
        rf:AddPAS( self:GetPos() )

        if hitATarget then
            owner:EmitSound( "npc/strider/fire.wav", 90, 150, 1, CHAN_AUTO, nil, nil, rf )
            owner:EmitSound( "npc/combine_gunship/attack_stop2.wav", 90, 120, 1, CHAN_AUTO, nil, nil, rf )
            self:SendWeaponAnim( ACT_VM_SECONDARYATTACK )
            self:SetNextIdle( CurTime() + self:SequenceDuration() )
            self:ApplyRecoil( nil, 1 )
        else
            owner:EmitSound( "buttons/button19.wav", 75, 100, 1, CHAN_AUTO, nil, nil, rf )
            owner:EmitSound( "buttons/button2.wav", 75, 90, 1, CHAN_AUTO, nil, nil, rf )
            self:SetReserveAmmo( self:GetReserveAmmo() + charge )
            self:SendWeaponAnim( ACT_VM_IDLE )

            -- Bonus hints
            if owner:GetInfoNum( "cfc_pvp_weapons_graviton_gun_bonus_hints_understood", 0 ) == 0 then
                local nextBonusHintTime = owner._cfcPvPWeapons_GravitonGun_NextBonusHintTime or 0

                if CurTime() >= nextBonusHintTime then
                    owner._cfcPvPWeapons_GravitonGun_NextBonusHintTime = CurTime() + bonusHintCooldown

                    net.Start( "CFC_PvPWeapons_GravitonGun_PlayBonusHints" )
                    net.Send( owner )
                end
            end
        end
    end
end

function SWEP:OnOvercharged()
    self:SetNextFire( CurTime() + self.Primary.Cooldown )

    if CLIENT then return end

    local owner = self:GetOwner()
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

    local knockback = self.Primary.OverchargeKnockback

    if knockback > 0 then
        local eyeAng = owner:EyeAngles()
        eyeAng.p = 0
        eyeAng.r = 0

        local vel = ( eyeAng:Up() - eyeAng:Forward() ):GetNormalized() * knockback

        owner:SetVelocity( vel )
    end

    self:Remove()
end


if SERVER then
    local uniqueIncr = 0


    function SWEP:DoGravitonHit( owner, victim )
        local primary = self.Primary

        if victim:Alive() then -- Only apply the graviton status if the initial damage wasn't enough to kill them.
            local chute = victim.cfcParachuteChute

            if IsValid( chute ) then
                chute:Close()
            end

            local accel = victim:GetVelocity():Length2D() * primary.GravitonAccelerationMult + primary.GravitonAccelerationAdd
            local oldStatus = victim._cfcPvPWeapons_GravitonGunStatus

            if oldStatus and not oldStatus.stale then
                accel = accel + oldStatus.accel * primary.GravitonStackMult
            end

            uniqueIncr = uniqueIncr + 1
            victim._cfcPvPWeapons_GravitonGunStatus = {
                id = uniqueIncr,
                attacker = owner,
                wep = self,
                accel = accel,
                fallDamageDiv = primary.GravitonFallDamageDiv,
                fallDamageEase = primary.GravitonFallDamageEase,
                fallDamageMult = primary.GravitonFallDamageMult,
                fallDamageThreshold = primary.GravitonFallDamageSpeedThreshdold,
                nextTrailTime = 0,
                trailInterval = primary.GravitonTrailInterval,
                trailLength = primary.GravitonTrailLength,
                trailSpeed = primary.GravitonTrailSpeed,
                trailOffsetSpread = primary.GravitonTrailOffsetSpread,
                trailAmount = primary.GravitonTrailAmount,
            }

            victim:StopSound( GRAVITON_STATUS_LOOP_SOUND )
            victim:EmitSound( GRAVITON_STATUS_LOOP_SOUND, 90, 220, 1, CHAN_AUTO )

            self:DoGravitonDropProp( victim )
            self:DoGravitonHorizontalToDownwards( victim )
        end

        -- Beam effect
        local attachID = owner:LookupAttachment( "anim_attachment_RH" )
        local eyeAng = owner:EyeAngles()
        local startPos

        if attachID then
            startPos = owner:GetAttachment( attachID ).Pos + eyeAng:Forward() * 25 + eyeAng:Up() * 5
        else
            startPos = owner:GetShootPos() + eyeAng:Forward() * 30 + eyeAng:Up() * -20
        end

        local endPos = victim:GetPos() + victim:OBBCenter()

        net.Start( "CFC_PvPWeapons_GravitonGun_MakeBeam" )
            net.WriteVector( startPos )
            net.WriteVector( endPos )
            net.WriteFloat( primary.GravitonBeamWidth )
            net.WriteFloat( primary.GravitonBeamDuration )
            net.WriteColor( primary.GravitonBeamColor )
        net.Broadcast()

        -- A bunch of tracers that converge on the victim from random directions.
        local eff = EffectData()
        eff:SetOrigin( endPos )
        eff:SetScale( 3000 )
        eff:SetFlags( 0 )

        for _ = 1, 30 do
            eff:SetStart( endPos + VectorRand( -700, 700 ) )
            util.Effect( "AirboatGunHeavyTracer", eff, true, true )
        end

        -- Victim sounds
        victim:EmitSound( "ambient/levels/citadel/portal_beam_shoot2.wav", 90, 110, 1, CHAN_AUTO )
    end

    function SWEP:DoGravitonDropProp( victim )
        local primary = self.Primary

        if not primary.GravitonDropProp then return end

        local wep = victim:GetActiveWeapon()
        if not IsValid( wep ) then return end
        if wep:GetClass() ~= "weapon_physgun" then return end

        local prop = physgunProps[victim]

        victim:ConCommand( "-attack" )

        local propKnockback = primary.GravitonDropPropKnockback
        if propKnockback == 0 then return end
        if not IsValid( prop ) then return end

        local physObj = prop:GetPhysicsObject()
        if not IsValid( physObj ) then return end

        local plyVel = victim:GetVelocity()
        plyVel.x = plyVel.x * 1.5 -- Make the knockback be skewed a bit more horizontal.
        plyVel.y = plyVel.y * 1.5

        local plySpeed = plyVel:Length()
        if plySpeed == 0 then return end

        local plyDir = plyVel / plySpeed

        physObj:SetVelocity( -plyDir * propKnockback )
    end

    function SWEP:DoGravitonHorizontalToDownwards( victim )
        local primary = self.Primary

        local horizToDownList = primary.GravitonHorizontalToDownwards
        if not horizToDownList then return end

        local dist = victim:GetPos():Distance( self:GetOwner():GetPos() )
        local horizToDown = 0

        for _, horizToDownListEntry in ipairs( horizToDownList ) do
            if dist >= horizToDownListEntry.dist then
                horizToDown = horizToDownListEntry.factor
            else
                break
            end
        end

        local velH = victim:GetVelocity()
        velH.z = 0

        local velHLength = velH:Length()
        if velHLength == 0 then return end

        local velHDir = velH / velHLength
        local downSpeed = velHLength * horizToDown
        local velToAdd = -velHDir * downSpeed + Vector( 0, 0, -downSpeed )

        victim:SetVelocity( velToAdd ) -- Player:SetVelocity() is additive.
    end

    function SWEP:ChargeThink()
        local now = CurTime()
        local chargeSpinAnimTime = self._chargeSpinAnimTime or 0

        if now >= chargeSpinAnimTime then
            self._chargeSpinAnimTime = now + 0.5
            self:SendWeaponAnim( ACT_VM_PRIMARYATTACK )
        end
    end


    hook.Add( "GetFallDamage", "CFC_PvPWeapons_GravitonGun_ApplyDamage", function( ply, speed )
        local gravStatus = ply._cfcPvPWeapons_GravitonGunStatus
        if not gravStatus then return end

        gravStatus.stale = true

        if speed < gravStatus.fallDamageThreshold then return end

        local frac = gravStatus.fallDamageEase( speed / gravStatus.fallDamageDiv )
        local damage = frac * gravStatus.fallDamageMult

        local attacker = gravStatus.attacker
        if not IsValid( attacker ) then return damage end

        local dmgInfo = DamageInfo()
        local wep = gravStatus.wep

        -- Rarely, it's possible for the weapon to be dropped and cleaned up, or for the attacker to die, before the victim hits the ground.
        -- We (probably) can't (and shouldn't) spawn a new weapon in time to use as a backup, so just don't set an inflictor.
        -- Unfortunately will end up with the wrong killfeed icon, but it's better than halting from an error.
        if IsValid( wep ) then
            dmgInfo:SetInflictor( wep )
        end

        dmgInfo:SetAttacker( attacker )
        dmgInfo:SetDamage( damage )
        dmgInfo:SetDamageType( DMG_FALL )

        ply:TakeDamageInfo( dmgInfo )

        local pos = ply:GetPos()

        sound.Play( "physics/body/body_medium_break" .. math.random( 2, 4 ) .. ".wav", pos, 80, math.Rand( 115, 120 ), 1 )
        sound.Play( "physics/body/body_medium_impact_hard" .. math.random( 1, 3 ) .. ".wav", pos, 80, math.Rand( 115, 120 ), 1 )
        sound.Play( "physics/metal/metal_canister_impact_soft2.wav", pos, 80, 60, 1 )
        sound.Play( "physics/metal/metal_computer_impact_bullet2.wav", pos, 80, 30, 1 )
        sound.Play( "npc/antlion_grub/squashed.wav", pos, 80, 100, 1 )

        util.ScreenShake( pos, speed / 20, 40, math.min( speed / 1500, 2 ), 500, true )

        return 0
    end )

    hook.Add( "OnPlayerHitGround", "CFC_PvPWeapons_GravitonGun_EndStatus", function( ply )
        local gravStatus = ply._cfcPvPWeapons_GravitonGunStatus
        if not gravStatus then return end
        if gravStatus.stale then return end

        local id = gravStatus.id

        gravStatus.stale = true
        ply:StopSound( GRAVITON_STATUS_LOOP_SOUND )

        -- Delay by 1 tick because GetFallDamage runs after OnPlayerHitGround
        timer.Simple( 0, function()
            if not IsValid( ply ) then return end

            local gravStatusNew = ply._cfcPvPWeapons_GravitonGunStatus
            if not gravStatusNew then return end
            if gravStatusNew.id ~= id then return end

            ply._cfcPvPWeapons_GravitonGunStatus = nil
        end )
    end )

    hook.Add( "PlayerDeath", "CFC_PvPWeapons_GravitonGun_EndStatus", function( ply )
        if not ply._cfcPvPWeapons_GravitonGunStatus then return end

        ply:StopSound( GRAVITON_STATUS_LOOP_SOUND )
        ply._cfcPvPWeapons_GravitonGunStatus = nil
    end )

    hook.Add( "OnEntityWaterLevelChanged", "CFC_PvPWeapons_GravitonGun_EndStatus", function( ent, _, new )
        if new < 2 then return end
        if not ent._cfcPvPWeapons_GravitonGunStatus then return end

        ent:StopSound( GRAVITON_STATUS_LOOP_SOUND )
        ent._cfcPvPWeapons_GravitonGunStatus = nil
    end )

    hook.Add( "DoPlayerDeath", "CFC_PvPWeapons_GravitonGun_UnderstandBonusHints", function( _, attacker, dmgInfo )
        if not IsValid( attacker ) then return end
        if not dmgInfo:IsDamageType( DMG_FALL ) then return end
        if attacker:GetInfoNum( "cfc_pvp_weapons_graviton_gun_bonus_hints_understood", 0 ) == 1 then return end

        local inflictor = dmgInfo:GetInflictor()
        if not IsValid( inflictor ) then return end
        if inflictor:GetClass() ~= "cfc_graviton_gun" then return end

        net.Start( "CFC_PvPWeapons_GravitonGun_UnderstandBonusHints" )
        net.Send( attacker )
    end )

    hook.Add( "Think", "CFC_PvPWeapons_GravitonGun_ApplyAcceleration", function()
        local dt = FrameTime()
        local now = CurTime()

        for _, ply in player.Iterator() do
            local gravStatus = ply._cfcPvPWeapons_GravitonGunStatus
            if not gravStatus then continue end
            if gravStatus.stale then continue end

            local accel = gravStatus.accel
            local velToAdd = Vector( 0, 0, -accel * dt ) -- Apply downwards acceleration.

            ply:SetVelocity( velToAdd )

            -- Make a trail or rushing wind effect from a bunch of short tracers that surround the victim.
            if gravStatus.nextTrailTime <= now then
                local trailInterval = gravStatus.trailInterval
                local trailOffsetSpread = gravStatus.trailOffsetSpread

                local startPos = ply:GetPos() + ply:OBBCenter()
                local endPos = startPos + ply:GetVelocity() * trailInterval * gravStatus.trailLength

                local eff = EffectData()
                eff:SetScale( ply:GetVelocity():Length() * gravStatus.trailSpeed )
                eff:SetFlags( 0 )

                for _ = 1, gravStatus.trailAmount do
                    local offset = VectorRand( -trailOffsetSpread, trailOffsetSpread )

                    eff:SetStart( startPos + offset )
                    eff:SetOrigin( endPos + offset )

                    util.Effect( "GaussTracer", eff, true, true )
                end

                gravStatus.nextTrailTime = now + trailInterval
            end
        end
    end )

    hook.Add( "OnPhysgunPickup", "CFC_PvPWeapons_GravitonGun_TrackPhysgunProps", function( ply, ent )
        physgunProps[ply] = ent
    end )

    hook.Add( "PhysgunDrop", "CFC_PvPWeapons_GravitonGun_TrackPhysgunProps", function( ply )
        physgunProps[ply] = nil
    end )

    hook.Add( "CFC_Parachute_CanSpaceEquip", "CFC_PvPWeapons_GravitonGun_BlockParachute", function( ply )
        if ply._cfcPvPWeapons_GravitonGunStatus then return false end
    end )
else
    local gravitonBeams = {}


    function SWEP:DoDrawCrosshair( x, y )
        local coneDeg = self:GetGravitonAimCone( math.Clamp( self:Clip1(), 1, self.Primary.ClipSize ) )
        local fov = self:GetFOV() - 15 -- Source Engine FOV is wacky
        if fov == 0 then return true end -- Avoid divide by zero

        local radius = 0.25 * ScrW() * coneDeg / fov
        radius = math.max( radius, 5 )

        if self:IsEmpty() or self:GetActivity() == ACT_VM_DRAW then
            surface.DrawCircle( x, y, radius, 255, 0, 0, 255 )
        else
            surface.DrawCircle( x, y, radius, 255, 255, 255, 255 )
        end

        return true
    end


    hook.Add( "PostDrawTranslucentRenderables", "CFC_PvPWeapons_GravitonGun_DrawBeams", function( _, skybox, skybox3d )
        if skybox or skybox3d then return end

        for i = #gravitonBeams, 1, -1 do
            local beam = gravitonBeams[i]
            local elapsed = CurTime() - beam.startTime
            local frac = elapsed / beam.duration

            if frac >= 1 then
                table.remove( gravitonBeams, i )
                continue
            end

            local width = beam.width
            local color = beam.color
            local alpha = 255 - 255 * frac
            color.a = alpha

            local scroll = math.Rand( 0, 1 )

            render.SetMaterial( gravitonBeamMat )
            render.DrawBeam( beam.start, beam.endpos, width, scroll, scroll + 1, color )
        end
    end )


    net.Receive( "CFC_PvPWeapons_GravitonGun_PlayBonusHints", function()
        if BONUS_HINTS_UNDERSTOOD:GetBool() then return end

        CFCPvPWeapons.PlayHints( bonusHints )
    end )

    net.Receive( "CFC_PvPWeapons_GravitonGun_UnderstandBonusHints", function()
        BONUS_HINTS_UNDERSTOOD:SetBool( true )
    end )

    net.Receive( "CFC_PvPWeapons_GravitonGun_MakeBeam", function()
        local startPos = net.ReadVector()
        local endPos = net.ReadVector()
        local width = net.ReadFloat()
        local duration = net.ReadFloat()
        local color = net.ReadColor()

        local beam = {
            start = startPos,
            endpos = endPos,
            width = width,
            duration = duration,
            color = color,
            startTime = CurTime(),
        }

        table.insert( gravitonBeams, beam )
    end )
end
