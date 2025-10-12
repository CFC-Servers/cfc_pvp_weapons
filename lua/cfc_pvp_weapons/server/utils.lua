CFCPvPWeapons = CFCPvPWeapons or {}


--- Applies blast damage and optionally hooks into damage events.
--- 
--- @param dmgInfo CTakeDamageInfo The damage info object containing damage details.
--- @param pos Vector The position where the blast damage originates.
--- @param radius number The radius of the blast damage.
--- @param etdCallback function? A callback function for the `EntityTakeDamage` hook with `HOOK_LOW` priority. 
--- If the callback returns a value, it will be used in the hook, which can be used to block the normal damage event.
--- Do NOT call any damage-inflicting functions in this callback to avoid feedback loops or misattribution.
--- @param petdCallback? function A callback function for the `PostEntityTakeDamage` hook. 
--- Similar to `etdCallback`, but triggered after the entity takes damage.
---
--- **Note:** If you need to inflict additional damage from the callback, use a timer, entity with a fuse, or similar workaround.
function CFCPvPWeapons.BlastDamageInfo( dmgInfo, pos, radius, etdCallback, petdCallback )
    if etdCallback then
        hook.Add( "EntityTakeDamage", "CFC_PvPWeapons_BlastDamageInfo", etdCallback, HOOK_LOW )
    end

    if petdCallback then
        hook.Add( "PostEntityTakeDamage", "CFC_PvPWeapons_BlastDamageInfo", petdCallback )
    end

    util.BlastDamageInfo( dmgInfo, pos, radius )

    if etdCallback then
        hook.Remove( "EntityTakeDamage", "CFC_PvPWeapons_BlastDamageInfo" )
    end

    if petdCallback then
        hook.Remove( "PostEntityTakeDamage", "CFC_PvPWeapons_BlastDamageInfo" )
    end
end

-- Similar to CFCPvPWeapons.BlastDamageInfo(), but for util.BlastDamage().
function CFCPvPWeapons.BlastDamage( inflictor, attacker, pos, radius, damage, etdCallback, petdCallback )
    local dmgInfo = DamageInfo()
    dmgInfo:SetInflictor( inflictor )
    dmgInfo:SetAttacker( attacker )
    dmgInfo:SetDamage( damage )

    CFCPvPWeapons.BlastDamageInfo( dmgInfo, pos, radius, etdCallback, petdCallback )
end

-- Spread is on 0-180 scale, output will be a unit vector.
function CFCPvPWeapons.SpreadDir( dir, pitchSpread, yawSpread )
    yawSpread = yawSpread or pitchSpread

    local ang = dir:Angle()
    local right = ang:Right()
    local up = ang:Up()

    ang:RotateAroundAxis( right, math.Rand( -pitchSpread, pitchSpread ) )
    ang:RotateAroundAxis( up, math.Rand( -yawSpread, yawSpread ) )

    return ang:Forward()
end

--- Deals damage to the weapon's owner, attributing the damage to the weapon and world.
---
--- @param wep SWEP The weapon instance.
--- @param amount number The amount of damage to deal.
--- @param force number? Optional force to apply to the damage. Defaults to amount * 0.25.
--- @param dir Vector? Optional direction of the force. Defaults to -owner:GetAimVector() for players, or Vector(0,0,1) for NPCs.
--- @param damageType number? Optional damage type. Defaults to DMG_BULLET.
function CFCPvPWeapons.DealSelfDamage( wep, amount, force, dir, damageType )
    local owner = wep:GetOwner()
    if not IsValid( owner ) then return end

    if not dir then
        if owner:IsPlayer() then
            dir = -owner:GetAimVector()
        else
            dir = Vector( 0, 0, 1 )
        end
    end

    local dmgInfo = DamageInfo()
    dmgInfo:SetDamage( amount )
    dmgInfo:SetAttacker( game.GetWorld() )
    dmgInfo:SetInflictor( wep )
    dmgInfo:SetDamageType( damageType or DMG_BULLET )
    dmgInfo:SetDamageForce( dir * ( force or ( amount * 0.25 ) ) )
    owner:TakeDamageInfo( dmgInfo )
end


hook.Add( "PlayerDeath", "CFC_PvPWeapons_CustomKillIcons", function( victim, inflictor, attacker )
    if inflictor == attacker then
        if not IsValid( attacker ) then return end
        if not attacker.GetActiveWeapon then return end

        inflictor = attacker:GetActiveWeapon()
    end

    if not IsValid( inflictor ) then return end
    if not inflictor.CFCPvPWeapons_GetKillIcon then return end

    local inflictorStr, flags = inflictor:CFCPvPWeapons_GetKillIcon( victim, attacker )
    if not inflictorStr then return end

    GAMEMODE:SendDeathNotice( attacker, inflictorStr, victim, flags or 0 )
end )
