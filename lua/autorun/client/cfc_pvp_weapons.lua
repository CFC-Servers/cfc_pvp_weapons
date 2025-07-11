CFCPvPWeapons = CFCPvPWeapons or {}

local hintConvars = {}

list.Set( "ContentCategoryIcons", "CFC", "icon16/star.png" )


--[[
    - Plays a set of hints.

    hints: (table or string)
        - If a string, provide the class of a SWEP that has a CFC_FirstTimeHints table.
        - If a table, use the following format:
            {
                {
                    Message = STRING,
                    Sound = STRING,
                    Duration = NUMBER,
                    DelayNext = NUMBER,
                },
                (...)
            }
--]]
function CFCPvPWeapons.PlayHints( hints )
    if type( hints ) == "string" then
        local swep = weapons.GetStored( hints )
        if not swep then return end

        hints = swep.CFC_FirstTimeHints
        if not hints then return end
    end

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
end


-- Most reliable way on client to listen when a weapon is equipped without using net messages.
-- Only misses if the weapon is given via initial loadout on spawn, which is fine in this case.
hook.Add( "HUDWeaponPickedUp", "CFC_PvPWeapons_FirstTimeHints", function( wep )
    if not IsValid( wep ) then return end

    local hints = wep.CFC_FirstTimeHints
    if not hints then return end

    local class = wep:GetClass()
    local convar = hintConvars[class]

    if not convar then
        convar = CreateClientConVar( "cfc_pvp_weapons_hint_seen_" .. class, "0", true, false )
        hintConvars[class] = convar
    end

    if convar:GetInt() == 1 then return end

    convar:SetInt( 1 )

    CFCPvPWeapons.PlayHints( hints )
end )
