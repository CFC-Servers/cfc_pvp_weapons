CFCPvPWeapons = CFCPvPWeapons or {}


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
local HITGROUP_NORMALIZERS = {}


local function initSetup()
    local hitgroupMults =
        hook.Run( "CFC_PvPWeapons_GetHitgroupMultipliers" ) or
        HITGROUP_MULTS_PER_GAMEMODE[engine.ActiveGamemode()] or
        DEFAULT_HITGROUP_MULTS

    CFCPvPWeapons.HITGROUP_MULTS = hitgroupMults
    CFCPvPWeapons.HITGROUP_NORMALIZERS = HITGROUP_NORMALIZERS

    for hitgroup, defaultMult in pairs( DEFAULT_HITGROUP_MULTS ) do
        local mult = hitgroupMults[hitgroup] or defaultMult
        local norm = 1 / mult

        if norm ~= norm then
            norm = 1 -- NaN
        end

        HITGROUP_NORMALIZERS[hitgroup] = norm
    end
end

hook.Add( "InitPostEntity", "CFC_PvPWeapons_HitgroupNormalization_InitSetup", initSetup )
if CurTime() > 500 then initSetup() end -- Also run if script is changed mid-session, for testing purposes.

hook.Add( "ScalePlayerDamage", "CFC_PvpWeapons_HitgroupNormalization", function( _, hitgroup, dmgInfo )
    local inflictor = dmgInfo:GetInflictor()

    if inflictor == dmgInfo:GetAttacker() then
        if not IsValid( inflictor ) then return end
        if not inflictor.GetActiveWeapon then return end

        inflictor = inflictor:GetActiveWeapon()
    end

    if not IsValid( inflictor ) then return end

    local normalizeTo = inflictor.CFCPvPWeapons_HitgroupNormalizeTo
    if not normalizeTo then return end

    normalizeTo = normalizeTo[hitgroup]
    if not normalizeTo then return end -- Allow the value to get scaled as usual.

    local norm = HITGROUP_NORMALIZERS[hitgroup] or 1

    dmgInfo:ScaleDamage( normalizeTo * norm )
end )
