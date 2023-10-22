AddCSLuaFile()
DEFINE_BASECLASS( "cfc_simple_ent_grenade_base" )
ENT.Base = "cfc_simple_ent_grenade_base"
ENT.Model = Model( "models/weapons/w_npcnade.mdl" )
ENT.Damage = 300
ENT.ExplodeTime = 2

ENT.Trail = true
ENT.TrailColor = "255 255 255"

function ENT:Explode()
    local selfPhys = self:GetPhysicsObject()
    selfPhys:SetVelocity( Vector( 0, 0, 300 ) )

    timer.Simple( 0.8, function()
        if not IsValid( self ) then return end

        local pos = self:WorldSpaceCenter()
        for _, ent in pairs( ents.FindInSphere( pos, 300 ) ) do
            if ent ~= self then
                local distance = pos:Distance( ent:WorldSpaceCenter() )

                local force = math.Clamp( ( 300 - distance ) / 300, 0, 1 ) * 3000
                local dir = ( ent:GetPos() - pos ):GetNormalized()
                local phys = ent:GetPhysicsObject()
                if IsValid( phys ) then
                    phys:SetVelocity( -dir * force )

                    debugoverlay.Line( pos, ent:WorldSpaceCenter(), 10, Color( 255, 0, 0 ), true )
                    debugoverlay.Text( ent:WorldSpaceCenter(), force, 10 )
                end
            end
        end

        self:Remove()
    end )
end
