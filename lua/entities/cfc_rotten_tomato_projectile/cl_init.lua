include( "shared.lua" )

function ENT:Initialize()
    self:SetModel( self.Model )
    if self.ModelMaterial then
        self:SetMaterial( self.ModelMaterial )
    end
    self:SetModelScale( self.ModelScale )
end

local hookName = "cfc_weapons_tomato_screentomato"
local tomatoMat = Material( "decals/cfctomatosplat.png" )
local tomatoes = {}
local hooking = nil
local aliveTime = 6
local next = 0

net.Receive( "cfc_weapons_tomato_screentomato", function()
    if next > CurTime() then return end
    next = CurTime() + 0.1

    local xExtent = ScrW()
    for _ = 1, math.random( 3, 6 ) do
        local new = {
            tomatoAlpha = 255,
            tomatoTime = CurTime() + aliveTime,
            randX = math.random( 0, xExtent ),
            rotation = math.random( -180, 180 )
        }
        table.insert( tomatoes, new )
    end

    if hooking then return end
    hooking = true

    hook.Add( "PostDrawHUD", hookName, function()
        local curTime = CurTime()

        -- animate each splat individually
        for index, tbl in ipairs( tomatoes ) do
            local tomatoTime = tbl.tomatoTime
            if tomatoTime < curTime then
                table.remove( tomatoes, index )
                if #tomatoes <= 0 then
                    hook.Remove( "PostDrawHUD", hookName )
                    hooking = nil
                    return
                end
            end

            local recentness = math.abs( ( tomatoTime - curTime ) - aliveTime ) / aliveTime
            local alphaRemoved = recentness * 255

            surface.SetDrawColor( 255, 255, 255, tbl.tomatoAlpha - alphaRemoved )
            surface.SetMaterial( tomatoMat )
            if tomatoMat:IsError() then return end

            surface.DrawTexturedRectRotated( tbl.randX, ScrH() / 2 + recentness * ScrH(), ScrW(), ScrH(), tbl.rotation )
        end
    end )
end )

local airSoundPath = "ambient/levels/canals/windmill_wind_loop1.wav"

local function stopAirSound( ent )
    if not IsValid( ent ) then return end
    local snd = ent.airSound

    if not snd or not snd:IsPlaying() then return end
    snd:Stop()
    snd = nil
end

function ENT:Think()
    local airSound = self.airSound
    local baseDamage = self.BaseDamage
    if not airSound then
        airSound = CreateSound( self, airSoundPath )
        self.airSound = airSound
        local lvl = 80 + ( baseDamage / 10 )
        airSound:SetSoundLevel( lvl )

        self:CallOnRemove( "cfc_tomato_whistle_stop", function() stopAirSound( self ) end )
    end

    if not airSound:IsPlaying() then
        airSound:Play()
    end

    local vel = self:GetVelocity():Length()
    local pitch = vel / 8
    local volume = vel / 1500

    airSound:ChangePitch( pitch )
    airSound:ChangeVolume( volume )

    local myPos = self:GetPos()
    if myPos:DistToSqr( LocalPlayer():GetPos() ) < 500^2 then
        local amp = pitch / 1000
        amp = amp * ( baseDamage / 10 )
        util.ScreenShake( myPos, amp, 20, 0.2, 500 )
    end
end