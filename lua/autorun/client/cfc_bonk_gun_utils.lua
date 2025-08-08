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

    timer.Create( "CFC_BonkGun_MovementDisabled", timeUntil, 1, function()
        hook.Remove( "SetupMove", "CFC_BonkGun_MovementDisabled" )
    end )
end )
