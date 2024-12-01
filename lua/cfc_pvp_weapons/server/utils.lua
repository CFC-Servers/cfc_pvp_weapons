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
