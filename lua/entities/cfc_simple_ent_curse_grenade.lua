AddCSLuaFile()

DEFINE_BASECLASS( "cfc_simple_ent_grenade_base" )

ENT.Base = "cfc_simple_ent_grenade_base"

ENT.Model = Model( "models/weapons/w_eq_fraggrenade.mdl" )

ENT.BeepEnabled = true
ENT.BeepDelay = 0.5
ENT.BeepDelayFast = 0.15
ENT.BeepFastThreshold = 1.5

ENT.Damage = 100 -- Doesn't actually deal damage, just used to compare against damage falloff for scaling the duration.
ENT.Radius = 300
ENT.Duration = 15
ENT.DurationMin = 3


local BLACKLISTED_EFFECTS = {
    -- FullUpdate is bad in pvp, causes a several-second freeze once it ends
    ["EntJitter"] = true,
    ["EntMagnet"] = true,
    ["FreshPaint"] = true,
    ["ThanosSnap"] = true,

    -- Irrelevant in pvp
    ["NoclipSpam"] = true,
    ["DisableNoclip"] = true,
    ["TextScramble"] = true,
    ["SeeingDouble"] = true,

    -- Too short of a duration to matter
    ["ColorModifyContinuous"] = true,
    ["TextureShuffleContinuous"] = true,
    ["RollAimIncremental"] = true,
    ["Schizophrenia"] = true,

    -- Not fun or too unfair
    ["JumpExplode"] = true,
    ["SprintExplode"] = true,
    ["Respawn"] = true,
    ["Clumsy"] = true,
    ["TheFloorIsLava"] = true,
    ["Drunk"] = true,
    ["NoInteract"] = true,
    ["Lidar"] = true,
    ["Ball"] = true,
    ["DoNoHarm"] = true,
    ["DoSomeHarm"] = true,

    -- Causes a big lagspike for the first time per session, and doesn't affect pvp a huge amount
    ["SoundShuffle"] = true,
    ["RandomSounds"] = true,

    -- Would be fun to include, but it'll end up causing accidental photos and toolgun clicks.
    ["WeaponIndecision"] = true,

    -- Allow FilmDevelopmentNoClear, but not the regular one.
    ["FilmDevelopment"] = true,

    -- Too much nausea
    ["SanFransisco"] = true,

    -- Too hard to notice or to realize what the source is
    ["NoHud"] = true,
    ["InputDrop"] = true,
    ["Rubberband"] = true,
    ["SpineBreak"] = true,
    ["Butterfingers"] = true,
    ["HealthDrain"] = true,
    ["OffsetAim"] = true,
}


function ENT:Initialize()
    BaseClass.Initialize( self )

    self:SetMaterial( "models/weapons/w_models/cfc_frag_grenade/frag_grenade_curse" )
end

function ENT:Explode()
    local pos = self:WorldSpaceCenter()
    local attacker = self:GetOwner()

    local dmgInfoInit = DamageInfo()
    dmgInfoInit:SetAttacker( attacker )
    dmgInfoInit:SetInflictor( self )
    dmgInfoInit:SetDamage( self.Damage )
    dmgInfoInit:SetDamageType( DMG_SONIC ) -- Don't use DMG_BLAST, otherwise rocket jump addons will also try to apply knockback (or even scale the damage)

    local damage = self.Damage
    local duration = self.Duration
    local durationMin = self.DurationMin

    CFCPvPWeapons.BlastDamageInfo( dmgInfoInit, pos, self.Radius, function( victim, dmgInfo )
        if victim == self then return true end
        if not IsValid( victim ) then return end
        if not victim:IsPlayer() then return true end
        if not victim:Alive() then return true end

        local effectData = CFCUlxCurse.GetRandomEffect( victim, BLACKLISTED_EFFECTS )

        if effectData then
            local durationEff = math.max( duration * dmgInfo:GetDamage() / damage, durationMin )
            local grenadeCurses = victim._cfcPvPWeapons_CurseGrenade_Curses

            if not grenadeCurses then
                grenadeCurses = {}
                victim._cfcPvPWeapons_CurseGrenade_Curses = grenadeCurses
            end

            CFCUlxCurse.ApplyCurseEffect( victim, effectData, durationEff )
            grenadeCurses[effectData.name] = CurTime() + durationEff
        end

        return true
    end )

    local effect = EffectData()
    effect:SetStart( pos )
    effect:SetOrigin( pos )

    util.Effect( "Explosion", effect, true, true )
    util.Effect( "cball_explode", effect, true, true )

    local radius = self.Radius

    effect:SetScale( 1.5 )
    effect:SetRadius( radius / 3 )
    effect:SetMagnitude( math.Rand( radius * 30 / 300, radius * 40 / 300 ) )
    effect:SetColor( 4 )
    effect:SetFlags( 0 )
    util.Effect( "cfc_pvp_weapons_curse_explosion", effect, true, true )

    sound.Play( "npc/assassin/ball_zap1.wav", pos, 90, 100 )
    sound.Play( "npc/roller/blade_out.wav", pos, 90, 100 )
    sound.Play( "npc/roller/mine/rmine_explode_shock1.wav", pos, 90, 100 )
    sound.Play( "npc/roller/mine/rmine_predetonate.wav", pos, 90, 110 )
    sound.Play( "npc/roller/mine/rmine_shockvehicle2.wav", pos, 90, 100 )
    sound.Play( "npc/roller/mine/rmine_taunt1.wav", pos, 90, 100 )

    self:Remove()
end

function ENT:PlayBeep()
    self:EmitSound( "buttons/button" .. math.random( 14, 19 ) .. ".wav", 75, 100 )

    local effect = EffectData()
    effect:SetOrigin( self:WorldSpaceCenter() )
    effect:SetScale( 0.4 )
    effect:SetRadius( 5 )
    effect:SetMagnitude( 2 )
    effect:SetColor( 2 )
    effect:SetFlags( 0 )
    util.Effect( "cfc_pvp_weapons_curse_explosion", effect, true, true )
end


if SERVER then
    -- Clear any unexpired cursed given by grenades when the player dies.
    hook.Add( "PostPlayerDeath", "CFC_PvPWeapons_CurseGrenade_EndCursesOnDeath", function( ply )
        local grenadeCurses = ply._cfcPvPWeapons_CurseGrenade_Curses
        if not grenadeCurses then return end

        local now = CurTime()

        for effectName, endTime in pairs( grenadeCurses ) do
            if endTime > now then
                CFCUlxCurse.StopCurseEffect( ply, effectName )
            end
        end

        ply._cfcPvPWeapons_CurseGrenade_Curses = nil
    end )
end
