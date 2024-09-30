CFCPvPWeapons = CFCPvPWeapons or {}


--[[
    - util.BlastDamageInfo(), with damage callbacks.
    - Do NOT call any damage-inflicting functions in the callbacks, it will cause feedback loops and/or misattribute the callback.
        - If you need to inflict damage from the callbacks, use a timer, entity with a fuse, etc.

    etdCallback: (optional) (function)
        - A callback function that listens during EntityTakeDamage with HOOK_LOW.
        - Whatever is returned by the function will be returned in the hook, if you need to block the normal damage event.
    petdCallback: (optional) (function)
        - A callback function that listens during PostEntityTakeDamage.
--]]
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
