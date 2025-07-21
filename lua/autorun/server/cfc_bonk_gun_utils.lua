CFCPvPWeapons = CFCPvPWeapons or {}

util.AddNetworkString( "CFC_BonkGun_PlayTweakedSound" )


local bonkedEnts = {}
local hitgroupNormalizers = {} -- Used for making bonk weapons ignore hitgroup damage scaling when calculating bonk force.

local IMPACT_ACCELERATION_THRESHOLD = 7000
local IMPACT_START_DELAY = 0.07
local IMPACT_LIFETIME = 6
local AIR_SHOT_REFUND_COOLDOWN = 0.01

local IsValid = IsValid
local VECTOR_ZERO = Vector( 0, 0, 0 )

local HITGROUP_MULTS_PER_GAMEMODE = {
    ["sandbox"] = { -- Also the fallback.
        [HITGROUP_GENERIC] = 1,
        [HITGROUP_HEAD] = 2,
        [HITGROUP_CHEST] = 1,
        [HITGROUP_STOMACH] = 1,
        [HITGROUP_LEFTARM] = 0.25,
        [HITGROUP_RIGHTARM] = 0.25,
        [HITGROUP_LEFTLEG] = 0.25,
        [HITGROUP_RIGHTLEG] = 0.25,
        [HITGROUP_GEAR] = 0.01,
    },
    ["terrortown"] = {
        [HITGROUP_GENERIC] = 1,
        [HITGROUP_HEAD] = 2,
        [HITGROUP_CHEST] = 1,
        [HITGROUP_STOMACH] = 1,
        [HITGROUP_LEFTARM] = 0.55,
        [HITGROUP_RIGHTARM] = 0.55,
        [HITGROUP_LEFTLEG] = 0.55,
        [HITGROUP_RIGHTLEG] = 0.55,
        [HITGROUP_GEAR] = 0.55,
    },
}
local DEFAULT_HITGROUP_MULTS = HITGROUP_MULTS_PER_GAMEMODE["sandbox"]


local function isBuildPlayer( ply )
    if not ply:IsPlayer() then return false end
    if not ply.IsInBuild then return false end
    return ply:IsInBuild()
end

local function enoughToKill( ply, dmgAmount )
    local health = ply:Health()
    local armor = ply:IsPlayer() and ply:Armor() or 0

    -- Note: this currently doesn't check for godmode
    if dmgAmount >= health + armor then
        return true
    end

    return false
end

local function playTweakedSound( ent, path, volume, pitch )
    if not IsValid( ent ) then return end
    if not path then return end

    local pos = ent:WorldSpaceCenter()
    volume = volume or 1
    pitch = pitch or 1

    -- Volume can't be set higher than 1 without using sound.PlayFile on client
    net.Start( "CFC_BonkGun_PlayTweakedSound" )
        net.WriteVector( pos )
        net.WriteString( path )
        net.WriteFloat( volume )
        net.WriteFloat( pitch )
    net.Broadcast()
end

local function playBonkSound( victim )
    local pitchOffset = math.Rand( -0.1, 0.1 )

    playTweakedSound( victim, "garrysmod/balloon_pop_cute.wav", 1.25, 0.7 + pitchOffset )
    playTweakedSound( victim, "physics/glass/glass_sheet_impact_hard1.wav", 1.25, 1.8 + pitchOffset )
end

local function playBonkImpactSound( attacker, victim )
    playTweakedSound( victim, "physics/flesh/flesh_impact_bullet" .. math.random( 1, 5 ) .. ".wav", 1.25, 1 )

    if attacker and attacker:IsPlayer() then
        attacker:EmitSound( "npc/headcrab_poison/ph_wallhit2.wav", 50, 100, 1 )
    end
end

-- Refunds a single shot of ammo if the victim is in the air due to being bonked
local function refundAirShot( attacker, victim, wep )
    if attacker.cfc_bonkCannotRefund then return end
    if not IsValid( wep ) then return end
    if victim:IsOnGround() then return end

    local bonkInfo = victim.cfc_bonkInfo or {}
    if not bonkInfo.IsBonked then return end

    local amountToRefund = wep.Bonk.AirShotsRefundAmmo
    if not amountToRefund or amountToRefund <= 0 then return end

    local clipAmmo = wep:Clip1()
    local clipMax = wep.Primary.ClipSize
    if clipAmmo >= clipMax then return end

    local newClipAmmount = math.min( clipAmmo + amountToRefund, clipMax )
    wep:SetClip1( newClipAmmount )
    attacker.cfc_bonkCannotRefund = true -- Only refund once per shot, so shooting two players doesn't give extra ammo

    timer.Simple( AIR_SHOT_REFUND_COOLDOWN, function()
        if not IsValid( attacker ) then return end
        attacker.cfc_bonkCannotRefund = false
    end )
end

local function counteractOpposingVelocity( ply, forceDir )
    local plyVel = ply:GetVelocity()
    local dot = plyVel:Dot( forceDir )

    if dot >= 0 then return VECTOR_ZERO end

    return -dot * forceDir
end

local function getBonkForce( attacker, victim, wep, dmgForce, dmgAmount, fromGround )
    local maxDamage = wep.Primary.Damage * wep.Primary.Count
    local damageMult = math.min( dmgAmount / maxDamage, wep.Bonk.PlayerForceMultMax )
    local bonkInfo = victim.cfc_bonkInfo or {}

    if bonkInfo.IsBonked then
        damageMult = damageMult * wep.Bonk.PlayerForceComboMult
    end

    if damageMult < wep.Bonk.PlayerForceIgnoreThreshold then return false end

    local dir = dmgForce:GetNormalized()
    local groundThresh = wep.Bonk.PlayerForceGroundThreshold
    local nearGround = false
    local isPly = victim:IsPlayer() -- NPCs don't seem to be quite as ground-sticky as players.

    if isPly and not fromGround and groundThresh > 0 then
        local tr = util.TraceHull( {
            start = victim:GetPos(),
            endpos = victim:GetPos() - Vector( 0, 0, groundThresh ),
            filter = victim,
            mins = victim:OBBMins(),
            maxs = victim:OBBMaxs(),
            mask = MASK_PLAYERSOLID
        } )

        if tr.Hit then
            nearGround = true
        end
    end

    -- Force the direction to have a significant upwards angle when on or near the ground.
    -- Otherwise, grounded players don't budge, and near-grounded players (i.e. jumping) immediately hit the ground with little impact.
    if isPly and fromGround or nearGround then
        local ang = attacker:EyeAngles() -- damageinfo force direction is an absolute mess when the victim is on the ground, use eye angles instead
        local pitch = math.min( ang.p, -wep.Bonk.PlayerForceGroundPitchMin )

        ang.p = pitch
        dir = ang:Forward()
    else
        damageMult = damageMult * wep.Bonk.PlayerForceAirMult
    end

    local counterForce = counteractOpposingVelocity( victim, dir ) * wep.Bonk.PlayerForceCounteractMult
    local forceStrength = wep.Bonk.PlayerForce * damageMult + wep.Bonk.PlayerForceAdd

    if not victim:IsPlayer() then
        forceStrength = forceStrength * wep.Bonk.NPCForceMult
    end

    local force = dir * forceStrength + counterForce

    -- Still need some flat z velocity to ensure they get off the ground
    if fromGround then
        force.z = force.z + wep.Bonk.PlayerForceGroundZAdd
    end

    return force
end

-- Disable victim's movement temporarily so they can't immediately cancel out the bonk effect.
local function disableMovement( victim, wep )
    local duration = wep.Bonk.DisableMovementDuration
    if not duration or duration <= 0 then return end

    local hookName = "CFC_BonkGun_DisableMovement_" .. victim:SteamID()

    hook.Add( "SetupMove", hookName, function( ply, mv, cmd )
        if ply ~= victim then return end

        mv:SetForwardSpeed( 0 )
        mv:SetSideSpeed( 0 )
        mv:SetUpSpeed( 0 )

        cmd:ClearMovement()
    end )

    timer.Create( hookName, duration, 1, function()
        hook.Remove( "SetupMove", hookName )
    end )
end

local function enableMovement( victim )
    local hookName = "CFC_BonkGun_DisableMovement_" .. victim:SteamID()

    timer.Remove( hookName )
    hook.Remove( "SetupMove", hookName )
end

local function bonkPlayerOrNPC( attacker, victim, wep, force )
    if not force then return end

    if victim:IsPlayer() then
        victim:SetVelocity( force )
        disableMovement( victim, wep )
    else
        local physObj = victim:GetPhysicsObject()

        if victim:GetClass() == "npc_strider" then
            force = force * 0.001 -- Striders don't have a physobj and state a really tiny OBB size despite how big they are. Just make the force negligable.
        elseif IsValid( physObj ) then
            force = force * 100 / physObj:GetMass() -- Don't affect heavy NPCs too much
        end

        victim:SetVelocity( victim:GetVelocity() + force )
    end

    playBonkSound( victim )

    if not wep.Bonk.ImpactEnabled then return end
    local wepClass = wep:GetClass()

    timer.Simple( IMPACT_START_DELAY, function()
        if not IsValid( victim ) then return end

        local bonkInfo = victim.cfc_bonkInfo

        if not bonkInfo then
            bonkInfo = {}
            victim.cfc_bonkInfo = bonkInfo
        end

        bonkInfo.Attacker = attacker
        bonkInfo.PrevVel = victim:GetVelocity()
        bonkInfo.IsBonked = true
        bonkInfo.ExpireTime = RealTime() + IMPACT_LIFETIME
        bonkInfo.Weapon = wep
        bonkInfo.WeaponClass = wepClass
        bonkedEnts[victim] = true
    end )
end

local function processDamage( attacker, victim, wep, dmg, fromGround )
    local dmgForce = dmg:GetDamageForce()

    if IsValid( victim ) and ( victim:IsPlayer() or victim:IsNPC() ) then
        fromGround = fromGround or victim:IsOnGround() -- If was from ground, then always from ground, in case the game moves players off the ground inbetween split damage events.
        local dmgAmount = dmg:GetDamage()

        -- When the victim is on the ground, dmgForce is pointed downwards, which makes the launch weak
        if fromGround then
            dmgForce.z = math.abs( dmgForce.z )
        end

        refundAirShot( attacker, victim, wep )

        if enoughToKill( victim, dmgAmount ) then
            -- Death ragdoll only needs a force multiplier
            dmg:SetDamageForce( dmgForce * wep.Bonk.PlayerForceMultRagdoll )

            return false -- No need for a manual bonk.
        end

        -- Undo the effects of hitgroup multipliers.
        if victim:IsPlayer() then
            local norm = hitgroupNormalizers[victim:LastHitGroup()] or 1
            dmgAmount = dmgAmount * norm
        end

        return true, fromGround, dmgForce, dmgAmount
    end

    dmg:SetDamageForce( dmgForce * wep.Bonk.PropForceMult )

    return false -- No need for a manual bonk.
end

local function handleImpact( ent, accel )
    local bonkInfo = ent.cfc_bonkInfo
    local attacker = IsValid( bonkInfo.Attacker ) and bonkInfo.Attacker or game.GetWorld()
    local wep = bonkInfo.Weapon

    if not IsValid( wep ) then
        wep = cfcEntityStubber.getWeapon( bonkInfo.WeaponClass )
    end

    local damageMult = wep.Bonk.ImpactDamageMult
    local damageMin = wep.Bonk.ImpactDamageMin
    local damageMax = wep.Bonk.ImpactDamageMax
    local damage = math.Clamp( accel * damageMult, damageMin, damageMax )

    if not IsValid( wep ) then
        wep = attacker
    end

    if not ent:IsOnGround() then
        playBonkImpactSound( attacker, ent )
    end

    -- Setting the inflictor to wep ensures a proper killfeed icon, and prevents the bonk effect from re-applying since normal gunshots have inflictor == attacker
    ent:TakeDamage( damage, attacker, wep )

    if ent:IsPlayer() then
        ent:SetLastHitGroup( HITGROUP_GENERIC )
        enableMovement( ent )
    end

    bonkInfo.IsBonked = nil
    bonkInfo.PrevVel = nil
    bonkInfo.Attacker = nil
    bonkInfo.Weapon = nil
    bonkInfo.WeaponClass = nil
    bonkedEnts[ent] = nil
end

local function detectImpact( ent, dt )
    local bonkInfo = ent.cfc_bonkInfo
    if not bonkInfo or not bonkInfo.IsBonked then return end

    local prevVel = bonkInfo.PrevVel

    if not prevVel then
        bonkInfo.PrevVel = ent:GetVelocity()

        return
    end

    if RealTime() > bonkInfo.ExpireTime then
        bonkInfo.IsBonked = nil
        bonkInfo.PrevVel = nil
        bonkInfo.Attacker = nil
        bonkInfo.Weapon = nil
        bonkInfo.WeaponClass = nil
        bonkedEnts[ent] = nil

        return
    end

    local curVel = ent:GetVelocity()
    local velDiff = curVel - prevVel
    local accel = velDiff:Length() / dt
    bonkInfo.PrevVel = curVel

    if accel < IMPACT_ACCELERATION_THRESHOLD then -- Not enough acceleration to be an impact
        if ent:IsOnGround() then -- Clear bonk status if ent landed on the ground smoothly or never launched up
            bonkInfo.IsBonked = nil
            bonkInfo.PrevVel = nil
            bonkInfo.Attacker = nil
            bonkInfo.Weapon = nil
            bonkInfo.WeaponClass = nil
            bonkedEnts[ent] = nil
        end

        return
    end

    handleImpact( ent, accel )
end


function CFCPvPWeapons.CollectBonkHits( wep )
    local bonkHits = {}
    wep._bonkHits = bonkHits

    hook.Add( "EntityTakeDamage", "CFC_BonkGun_CollectBonkHits", function( victim, dmg )
        if not IsValid( victim ) then return end
        if isBuildPlayer( victim ) then return end

        local attacker = dmg:GetAttacker()
        if not IsValid( attacker ) then return end
        if not attacker.GetActiveWeapon then return end

        if dmg:GetInflictor() ~= attacker then return end -- Prevent turrets and etc from bonking.
        if attacker:GetActiveWeapon() ~= wep then return end -- Only collect hits for the current weapon.

        local hit = bonkHits[victim]
        local needsManualBonk, fromGround, dmgForce, dmgStrength = processDamage( attacker, victim, wep, dmg, hit and hit.fromGround )
        if not needsManualBonk then return end

        -- Collect hits together.
        if not hit then
            hit = {
                strength = 0, -- Damage after undoing the effects of hitgroup multipliers.
                force = Vector( 0, 0, 0 ),
                fromGround = fromGround,
                attacker = attacker,
            }
            bonkHits[victim] = hit
        end

        hit.strength = hit.strength + dmgStrength
        hit.force = hit.force + dmgForce
    end, HOOK_LOW )
end

-- Should not be called manually.
function CFCPvPWeapons.ApplyBonkHits( wep )
    hook.Remove( "EntityTakeDamage", "CFC_BonkGun_CollectBonkHits" )

    local bonkHits = wep._bonkHits
    if not bonkHits then return end

    for victim, hit in pairs( bonkHits ) do
        if not victim:Alive() then continue end

        local force = getBonkForce( hit.attacker, victim, wep, hit.force, hit.strength, hit.fromGround )
        bonkPlayerOrNPC( hit.attacker, victim, wep, force )

        bonkHits[victim] = nil
    end

    wep._bonkHits = nil
end


hook.Add( "Think", "CFC_BonkGun_DetectImpact", function()
    local dt = FrameTime()

    for ent in pairs( bonkedEnts ) do
        detectImpact( ent, dt )
    end
end )


local function initSetup()
    local hitgroupMults =
        hook.Run( "CFC_PvPWeapons_BonkGun_GetHitgroupMultipliers" ) or
        HITGROUP_MULTS_PER_GAMEMODE[engine.ActiveGamemode()] or
        DEFAULT_HITGROUP_MULTS

    for hitgroup, defaultMult in pairs( DEFAULT_HITGROUP_MULTS ) do
        local mult = hitgroupMults[hitgroup] or defaultMult
        local norm = 1 / mult

        if norm ~= norm then
            norm = 1 -- NaN
        end

        hitgroupNormalizers[hitgroup] = norm
    end
end

hook.Add( "InitPostEntity", "CFC_PvPWeapons_BonkGun_InitSetup", initSetup )
if CurTime() > 500 then initSetup() end -- Also run if script is changed mid-session, for testing purposes.
