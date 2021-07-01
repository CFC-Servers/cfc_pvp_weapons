AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
include( "shared.lua" )

function ENT:Unfurl()
    self.chuteIsUnfurled = true

    self:EmitSound( "physics/flesh/flesh_impact_hard1.wav", 75, 100, 1 )

    net.Start( "CFC_Parachute_DefineChuteUnfurlStatus" )
    net.WriteEntity( self )
    net.WriteBool( true )
    net.Broadcast()
end

function ENT:Furl()
    self.chuteIsUnfurled = false

    self:EmitSound( "physics/flesh/flesh_impact_hard2.wav", 75, 100, 1 )

    net.Start( "CFC_Parachute_DefineChuteUnfurlStatus" )
    net.WriteEntity( self )
    net.WriteBool( false )
    net.Broadcast()
end

function ENT:Open()
    self.chuteIsOpen = true
    self:DrawShadow( true )

    self:EmitSound( "physics/cardboard/cardboard_box_break3.wav", 75, 100, 1 )
    self:SetColor( Color( 255, 255, 255, 255 ) )
end

function ENT:Close()
    self.chuteIsOpen = false
    self:DrawShadow( false )

    self:EmitSound( "physics/wood/wood_crate_impact_hard4.wav", 75, 100, 1 )
    self:SetColor( Color( 255, 255, 255, 0 ) )
end

function ENT:Initialize()  

    local owner = self.chuteOwner

    if not IsValid( owner ) then
        timer.Simple( 0.02, function()
            if IsValid( self.chuteOwner ) then
                self:Initialize()

                return
            end

            self:Remove()
        end )

        return
    end

    self:SetModel( "models/cfc/parachute/chute.mdl" )
    self:PhysicsInit( SOLID_VPHYSICS )
    self:SetSolid( SOLID_VPHYSICS )
    self:DrawShadow( false )
    self:SetCollisionGroup( COLLISION_GROUP_IN_VEHICLE )
    self:SetRenderMode( RENDERMODE_TRANSCOLOR )

    self:PhysWake()
end
