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
local hooking
local aliveTime = 6
local next = 0

net.Receive( "cfc_weapons_tomato_screentomato", function()
    if next > CurTime() then return end
    next = CurTime() + 0.1

    local xExtent = ScrW()
    for _ = 1, math.random( 2, 4 ) do
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

    hook.Add( "RenderScreenspaceEffects", hookName, function()
        local curTime = CurTime()

        -- animate each splat individually
        for index, tbl in ipairs( tomatoes ) do
            local tomatoTime = tbl.tomatoTime
            if tomatoTime < curTime then
                table.remove( tomatoes, index )
                if #tomatoes <= 0 then
                    hook.Remove( "RenderScreenspaceEffects", hookName )
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