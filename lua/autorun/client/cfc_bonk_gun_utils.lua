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
