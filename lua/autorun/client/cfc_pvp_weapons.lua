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


-- override baseclass DrawWeaponSelection to accept actual materials instead of texids, so it can handle pngs with no bs
local function drawTexOverride( self, x, y, wide, tall, alpha )

    -- Set us up the texture
    surface.SetDrawColor( 255, 255, 255, alpha )
    surface.SetMaterial( self.glee_WepSelectIcon )

    -- Lets get a sin wave to make it bounce
    local fsin = 0

    if ( self.BounceWeaponIcon == true ) then
        fsin = math.sin( CurTime() * 10 ) * 5
    end

    -- Borders
    y = y + 10
    x = x + 10
    wide = wide - 20

    -- Draw that mother
    surface.DrawTexturedRect( x + fsin, y - fsin,  wide - fsin * 2 , ( wide / 2 ) + fsin )

    -- Draw weapon info box
    self:PrintWeaponInfo( x + wide + 20, y + tall * 0.95, alpha )
end

local white = Color( 255, 255, 255 )

-- function that setups the weapon's PrintName translation, select icon. and killicon, all in one place
-- from glee!
-- not useful for stuff with special icons like the stinger
function CFCPvPWeapons.CL_SetupSwep( SWEP, class, texture )
    language.Add( class, SWEP.PrintName )
    killicon.Add( class, texture, white )

    local mat = Material( texture, "alphatest" )
    if not mat:IsError() then
        SWEP.glee_WepSelectIcon = mat
        SWEP.DrawWeaponSelection = drawTexOverride
    else
        error( "Error loading weapon icon texture for " .. class .. "\n" .. mat:GetName() .. "\n" .. texture )
    end
end

function CFCPvPWeapons.CL_SetupSent( ENT, class, texture )
    language.Add( class, ENT.PrintName )
    killicon.Add( class, texture, white )
end