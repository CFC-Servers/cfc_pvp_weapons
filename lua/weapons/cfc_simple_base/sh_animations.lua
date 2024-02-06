AddCSLuaFile()

DEFINE_BASECLASS( "weapon_base" )

local replacements = {
    -- Pistol
    [ACT_HL2MP_IDLE_PISTOL] = ACT_HL2MP_IDLE_REVOLVER,
    [ACT_HL2MP_WALK_PISTOL] = ACT_HL2MP_WALK_REVOLVER,
    [ACT_HL2MP_RUN_PISTOL] = ACT_HL2MP_RUN_REVOLVER,
    -- Shotgun
    [ACT_HL2MP_IDLE_SHOTGUN] = ACT_HL2MP_IDLE_AR2,
    [ACT_HL2MP_IDLE_CROUCH_SHOTGUN] = ACT_HL2MP_IDLE_CROUCH_AR2,
    [ACT_HL2MP_WALK_SHOTGUN] = ACT_HL2MP_WALK_AR2,
    [ACT_HL2MP_WALK_CROUCH_SHOTGUN] = ACT_HL2MP_WALK_CROUCH_AR2,
    [ACT_HL2MP_RUN_SHOTGUN] = ACT_HL2MP_RUN_AR2,
    -- Passive
    [ACT_HL2MP_WALK_CROUCH_PASSIVE] = ACT_HL2MP_WALK_CROUCH,
    [ACT_HL2MP_IDLE_CROUCH_PASSIVE] = ACT_HL2MP_IDLE_CROUCH
}

function SWEP:TranslateWeaponAnim( act )
    return act
end

function SWEP:SendTranslatedWeaponAnim( act )
    act = self:TranslateWeaponAnim( act )

    if not act then
        return
    end

    self:SendWeaponAnim( act )
end

function SWEP:TranslateActivity( act )
    local custom = self.CustomHoldType
    custom = custom and custom[act]

    if custom then return custom end

    local translated = BaseClass.TranslateActivity( self, act )

    return replacements[translated] and replacements[translated] or translated
end
