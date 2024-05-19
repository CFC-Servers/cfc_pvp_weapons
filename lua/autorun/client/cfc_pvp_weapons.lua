list.Set( "ContentCategoryIcons", "CFC", "icon16/star.png" )

local hasSeenClassThisSession = {}


-- Most reliable way on client to listen when a weapon is equipped without using net messages.
-- Only misses if the weapon is given via initial loadout on spawn, which is fine in this case.
hook.Add( "HUDWeaponPickedUp", "CFC_PvPWeapons_FirstTimeHints", function( wep )
    if not IsValid( wep ) then return end

    local hints = wep.CFC_FirstTimeHints
    if not hints then return end

    local class = wep:GetClass()
    if hasSeenClassThisSession[class] then return end

    hasSeenClassThisSession[class] = true

    local hintInd = 1

    local function showHint()
        local hint = hints[hintInd]
        if not hint then return end

        local message = hint.Message
        local soundPath = hint.Sound
        local duration = hint.Duration or 8
        local delayNext = hint.DelayNext or 0

        if soundPath == nil then
            soundPath = "ambient/water/drip1.wav"
        end

        notification.AddLegacy( message, NOTIFY_HINT, duration )

        if soundPath then
            surface.PlaySound( soundPath )
        end

        hintInd = hintInd + 1

        timer.Simple( delayNext, showHint )
    end

    showHint()
end )
