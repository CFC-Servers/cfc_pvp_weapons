AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
include( "shared.lua" )

local COLOR_SHOW = Color( 255, 255, 255, 255 )
local COLOR_HIDE = Color( 255, 255, 255, 0 )

local isValid = IsValid

function ENT:Unfurl()
    self.chuteIsUnfurled = true

    self:EmitSound( "physics/flesh/flesh_impact_hard1.wav", 85, 100, 1 )

    net.Start( "CFC_Parachute_DefineChuteUnfurlStatus" )
    net.WriteEntity( self )
    net.WriteBool( true )
    net.Broadcast()
end

function ENT:Furl()
    self.chuteIsUnfurled = false

    self:EmitSound( "physics/flesh/flesh_impact_hard2.wav", 85, 100, 1 )

    net.Start( "CFC_Parachute_DefineChuteUnfurlStatus" )
    net.WriteEntity( self )
    net.WriteBool( false )
    net.Broadcast()
end

function ENT:Open()
    self.chuteIsOpen = true
    self:SetNoDraw( false )

    self:EmitSound( "physics/cardboard/cardboard_box_break3.wav", 85, 100, 1 )
    self:SetColor( COLOR_SHOW )
end

function ENT:Close()
    self.chuteIsOpen = false
    self:SetNoDraw( true )

    self:EmitSound( "physics/wood/wood_crate_impact_hard4.wav", 85, 100, 1 )
    self:SetColor( COLOR_HIDE )
end

function ENT:Initialize()
    local owner = self.chuteOwner

    if not isValid( owner ) then
        timer.Simple( 0.02, function()
            if isValid( self.chuteOwner ) then
                self:Initialize()

                return
            end

            self:Remove()
        end )

        return
    end

    self:SetModel( "models/cfc/parachute/chute.mdl" )
    self:PhysicsInit( SOLID_NONE )
    self:SetSolid( SOLID_NONE )
    self:DrawShadow( false )
    self:SetCollisionGroup( COLLISION_GROUP_IN_VEHICLE )
    self:SetRenderMode( RENDERMODE_TRANSCOLOR )

    self:PhysWake()
end

function ENT:Think()
    local wep = self.chutePack

    if not isValid( wep ) then return end

    wep:CloseIfOnGround()
    wep:CloseIfInWater()
    self:NextThink( CurTime() )

    return true
end
