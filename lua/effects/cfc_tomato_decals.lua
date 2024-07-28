
AddCSLuaFile()

local mat = Material( "decals/cfctomatosplat.png" )

function EFFECT:Init( data )
    local pos = data:GetOrigin()
    -- tomato decals
    local normal = data:GetNormal()
    for _ = 1, 4 do
        local currNormal = normal + ( VectorRand() * 0.25 )
        local currPos = pos + ( -normal * math.random( 10, 45 ) )
        local res = util.QuickTrace( currPos + -currNormal * 5, currNormal * math.random( 75, 125 ) )
        if res.Hit then
            util.DecalEx( mat, res.Entity, res.HitPos + -normal, -normal + ( VectorRand() * 0.2 ), color_white, math.Rand( 0.05, 0.3 ), math.Rand( 0.05, 0.2 ) )
        end
    end
end

function EFFECT:Think()
    return false
end

function EFFECT:Render()
end
