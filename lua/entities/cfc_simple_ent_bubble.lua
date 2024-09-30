AddCSLuaFile()

ENT.Base = "base_anim"
ENT.Type = "anim"

ENT.AutomaticFrameAdvance = true

ENT.Model = Model( "models/cfc_pvp_weapons/bubble.mdl" )


function ENT:SetupDataTables()
    self:NetworkVar( "Float", 0, "BubbleRadius" )
end

function ENT:Initialize()
    self:SetModel( self.Model )
    self:DrawShadow( false )

    if CLIENT then
        local radius = self:GetBubbleRadius()
        self:SetRenderBounds( Vector( -radius, -radius, -radius ), Vector( radius, radius, radius ) )

        self:NetworkVarNotify( "BubbleRadius", function( ent, _, _, new )
            ent:SetRenderBounds( Vector( -new, -new, -new ), Vector( new, new, new ) )
        end )
    end
end

function ENT:SetUpPhysics()
    self:PhysicsInit( SOLID_VPHYSICS )
    self:SetMoveType( MOVETYPE_VPHYSICS )
    self:SetSolid( SOLID_VPHYSICS )
    self:SetNotSolid( true )
    self:GetPhysicsObject():EnableMotion( false )
end

function ENT:ACF_PreDamage()
    return false
end
