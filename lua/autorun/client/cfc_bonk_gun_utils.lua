local function curve( x )
    local y = 1 - math.ease.OutCirc( x )

    if y < 0 then return 0 end

    return y
end

local function getCurvePoints( width, height, numSegments, outerUV, innerUV, moveIn )
    width = width / 2
    height = height / 2

    local a = moveIn or 0
    local aAlt = 1 - a

    local wa = width * a
    local ha = height * a
    local wAlt = width * aAlt
    local hAlt = height * aAlt

    local midUV = ( innerUV + outerUV ) / 2

    local x = 0
    local y = curve( x )
    local step = 1 / numSegments
    local points = {
        { x = 0, y = 0, u = outerUV, v = outerUV },
        { x = 0, y = hAlt + ha, u = midUV, v = midUV },
        { x = x * wAlt + wa, y = y * hAlt + ha, u = innerUV, v = innerUV },
    }

    while y > 0 do
        x = x + step
        y = curve( x )

        table.insert( points, { x = x * wAlt + wa, y = y * hAlt + ha, u = innerUV, v = innerUV } )
    end

    table.insert( points, { x = wAlt + wa, y = 0, u = midUV, v = midUV } )

    return points
end

local function makeVignettePolys( width, height, numSegments, outerUV, innerUV, moveIn )
    local curvePoints = getCurvePoints( width, height, numSegments, outerUV, innerUV, moveIn )
    local curvePointsReverse = table.Reverse( curvePoints )

    local point1 = table.remove( curvePointsReverse, #curvePointsReverse )
    table.insert( curvePointsReverse, 1, point1 )

    local poly1 = {} -- top left (needs reverse)
    local poly2 = {} -- top right
    local poly3 = {} -- bottom right (needs reverse)
    local poly4 = {} -- bottom left

    for i, point in ipairs( curvePoints ) do
        local x = point.x
        local y = point.y
        local u = point.u
        local v = point.v

        poly2[i] = {
            x = width - x,
            y = y,
            u = u,
            v = v
        }

        poly4[i] = {
            x = x,
            y = height - y,
            u = u,
            v = v
        }
    end

    for i, point in ipairs( curvePointsReverse ) do
        local x = point.x
        local y = point.y
        local u = point.u
        local v = point.v

        poly1[i] = {
            x = x,
            y = y,
            u = u,
            v = v,
        }

        poly3[i] = {
            x = width - x,
            y = height - y,
            u = u,
            v = v,
        }
    end

    return { poly1, poly2, poly3, poly4 }
end


net.Receive( "CFC_BonkGun_PlayTweakedSound", function()
    local pos = net.ReadVector()
    local path = net.ReadString()
    local volume = net.ReadFloat()
    local pitch = net.ReadFloat()

    -- sound.PlayFile doesn't properly cut off distant sounds
    if EyePos():Distance( pos ) > 1000 then return end

    sound.PlayFile( "sound/" .. path, "3d stereo noblock noplay", function( station )
        if not IsValid( station ) then return end

        station:SetPos( pos )
        station:SetVolume( volume )
        station:SetPlaybackRate( pitch )
        station:Play()
    end )
end )

net.Receive( "CFC_BonkGun_DisableMovement", function()
    local endTime = net.ReadFloat()
    local timeUntil = endTime - CurTime()
    if timeUntil <= 0 then return end

    hook.Add( "SetupMove", "CFC_BonkGun_MovementDisabled", function( _, mv, cmd )
        mv:SetForwardSpeed( 0 )
        mv:SetSideSpeed( 0 )
        mv:SetUpSpeed( 0 )

        cmd:ClearMovement()
    end )

    local numSegments = 30
    local outerIntensity = 0.4
    local moveIn = 0.3
    local vignetteMat = Material( "gui/gradient_up" )
    local polys = makeVignettePolys( ScrW(), ScrH(), numSegments, outerIntensity, 0.01, moveIn )

    hook.Add( "HUDPaintBackground", "CFC_BonkGun_MovementDisabled_DrawVignette", function()
        surface.SetDrawColor( 0, 0, 200, 150 )
        surface.SetMaterial( vignetteMat )

        for _, poly in ipairs( polys ) do
            surface.DrawPoly( poly )
        end
    end )

    timer.Create( "CFC_BonkGun_MovementDisabled", timeUntil, 1, function()
        hook.Remove( "SetupMove", "CFC_BonkGun_MovementDisabled" )
        hook.Remove( "HUDPaintBackground", "CFC_BonkGun_MovementDisabled_DrawVignette" )
    end )
end )
