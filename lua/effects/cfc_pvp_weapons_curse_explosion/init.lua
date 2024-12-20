local LIFETIME = 2
local SPEED_MIN = 20 -- Multiplied by :GetColor() (which is a 0-255 number for effects)
local SPEED_MAX = 25 -- Multiplied by :GetColor() (which is a 0-255 number for effects)
local AIR_RESISTANCE = 5
local ROLL_SPEED_MIN = math.rad( 30 )
local ROLL_SPEED_MAX = math.rad( 360 )

local PARTICLE_INFOS = {
    {
        -- Near-black violet smoke
        mat = "particle/particle_smokegrenade",
        color = Color( 32, 0, 65 ),
        colorIntensityMin = 0,
        colorIntensityMax = 1,
        startSize = 50,
        endSize = 50,
        startAlpha = 255,
        endAlpha = 0,
        speedMult = 1,
        amountPerMagnitude = 5,
        flagToMakeScaleAffectSize = 0, -- :SetScale() will always affect size
    },
    {
        -- Blue sparkle
        mat = "sprites/orangeflare1",
        color = Color( 50, 0, 200 ),
        colorIntensityMin = 0.75,
        colorIntensityMax = 1,
        startSize = 0,
        endSize = 10,
        startAlpha = 255,
        endAlpha = 0,
        speedMult = 2,
        amountPerMagnitude = 1,
        flagToMakeScaleAffectSize = 1, -- :SetScale() will affect size if flag 1 is set
    },
    {
        -- Purple sparkle
        mat = "sprites/glow04_noz_gmod",
        color = Color( 125, 0, 200 ),
        colorIntensityMin = 0.5,
        colorIntensityMax = 1,
        startSize = 0,
        endSize = 10,
        startAlpha = 255,
        endAlpha = 0,
        speedMult = 2,
        amountPerMagnitude = 1,
        flagToMakeScaleAffectSize = 2, -- :SetScale() will affect size if flag 2 is set
    },
}

local PI_DOUBLE = math.pi * 2


function EFFECT:Init( data )
    local pos = data:GetOrigin()
    local scale = data:GetScale() -- Changes the size of certain particles, depending on the effect's flags.
    local radius = data:GetRadius() -- Determines the radius to spawn particles in.
    local magnitude = data:GetMagnitude() -- Determines the number of particles to spawn.
    local speedMult = data:GetColor() -- Multiplier against the speed of particles. 0-255. See SPEED_MIN and SPEED_MAX.
    local flags = data:GetFlags() -- Bitflags for various options.

    self.Emitter = ParticleEmitter( pos )
    self:DoExplosion( pos, scale, radius, magnitude, speedMult, flags )
end

function EFFECT:Think()
    self.Emitter:Finish()
    return false
end

function EFFECT:Render()

end

function EFFECT:DoExplosion( pos, scale, radius, magnitude, speedMult, flags )
    local emitter = self.Emitter
    local speedMin = SPEED_MIN * speedMult
    local speedMax = SPEED_MAX * speedMult

    for _, particleInfo in ipairs( PARTICLE_INFOS ) do
        local mat = particleInfo.mat
        local color = particleInfo.color
        local colorIntensityMin = particleInfo.colorIntensityMin
        local colorIntensityMax = particleInfo.colorIntensityMax
        local startSize = particleInfo.startSize * scale
        local endSize = particleInfo.endSize * scale
        local startAlpha = particleInfo.startAlpha
        local endAlpha = particleInfo.endAlpha
        local speedMultInfo = particleInfo.speedMult
        local amountPerMagnitude = particleInfo.amountPerMagnitude
        local flagToMakeScaleAffectSize = particleInfo.flagToMakeScaleAffectSize

        if bit.band( flagToMakeScaleAffectSize, flags ) == flagToMakeScaleAffectSize then
            startSize = startSize * scale
            endSize = endSize * scale
        end

        local colorR = color.r
        local colorG = color.g
        local colorB = color.b

        for _ = 1, math.ceil( magnitude * amountPerMagnitude ) do
            local particle = emitter:Add( mat, pos + VectorRand():GetNormalized() * math.Rand( 0, radius ) )
            if particle then
                local colorIntensity = math.Rand( colorIntensityMin, colorIntensityMax )

                particle:SetVelocity( VectorRand():GetNormalized() * math.Rand( speedMin, speedMax ) * speedMultInfo )
                particle:SetDieTime( LIFETIME )
                particle:SetStartAlpha( startAlpha )
                particle:SetEndAlpha( endAlpha )
                particle:SetStartSize( startSize )
                particle:SetEndSize( endSize )
                particle:SetRoll( math.Rand( 0, PI_DOUBLE ) )
                particle:SetRollDelta( math.Rand( ROLL_SPEED_MIN, ROLL_SPEED_MAX ) )
                particle:SetColor( colorR * colorIntensity, colorG * colorIntensity, colorB * colorIntensity )
                particle:SetAirResistance( AIR_RESISTANCE )
                particle:SetCollide( false )
                particle:SetBounce( 0 )
            end
        end
    end
end
