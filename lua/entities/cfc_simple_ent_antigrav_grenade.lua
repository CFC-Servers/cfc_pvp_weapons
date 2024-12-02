AddCSLuaFile()

DEFINE_BASECLASS( "cfc_simple_ent_bubble_grenade" )

ENT.Base = "cfc_simple_ent_bubble_grenade"

ENT.Model = Model( "models/weapons/w_eq_fraggrenade.mdl" )

ENT.BeepEnabled = true
ENT.BeepDelay = 1
ENT.BeepDelayFast = 0.3
ENT.BeepFastThreshold = 1.5

ENT.BubbleRadius = 250
ENT.BubbleDuration = 7
ENT.BubbleGrowDuration = 0.25
ENT.BubbleShrinkDuration = 0.25
ENT.EffectLingerOutsideBubble = 0

ENT.GravityMult = -2.5
ENT.PushStrength = 260 -- Pushes the player up to get them off the ground.
ENT.FuseOnImpact = 1 -- On the first impact, shortens the remaining fuse time to this.


function ENT:Initialize()
    BaseClass.Initialize( self )

    self:SetMaterial( "models/weapons/w_models/cfc_frag_grenade/frag_grenade_antigrav" )

    local fuseOnImpact = self.FuseOnImpact

    if SERVER and fuseOnImpact then
        local fuseShortened = false

        function self:PhysicsCollide()
            local fuseLeft = self._explodeDelay
            if not fuseLeft then return end
            if fuseShortened then return end

            fuseShortened = true

            if fuseLeft > fuseOnImpact then
                self:SetTimer( fuseOnImpact )
            end
        end
    end
end

function ENT:CreateBubble()
    local pos = self:WorldSpaceCenter()
    local bubble = ents.Create( "cfc_simple_ent_bubble" )
    bubble:SetPos( pos )
    bubble:SetAngles( Angle( 0, 0, 0 ) )
    bubble:SetMaterial( "models/props_combine/portalball001_sheet" )
    bubble:Spawn()
    bubble:SetBubbleRadius( self.BubbleRadius )

    local cosmeticBubbles = {}

    local bubble2 = ents.Create( "cfc_simple_ent_bubble" )
    bubble2:SetPos( pos )
    bubble2:SetAngles( Angle( 0, 0, 0 ) )
    bubble2:SetMaterial( "sprites/heatwave" )
    bubble2:Spawn()
    bubble2:SetBubbleRadius( self.BubbleRadius )
    bubble2:SetColor( Color( 255, 255, 255, 100 ) )
    bubble2:SetRenderMode( RENDERMODE_TRANSCOLOR )
    bubble2._bubbleScaleMult = 1
    table.insert( cosmeticBubbles, bubble2 )

    local bubble3 = ents.Create( "cfc_simple_ent_bubble" )
    bubble3:SetPos( pos )
    bubble3:SetAngles( Angle( 0, 0, 0 ) )
    bubble3:SetMaterial( "sprites/heatwave" )
    bubble3:Spawn()
    bubble3:SetBubbleRadius( self.BubbleRadius )
    bubble3:SetColor( Color( 255, 255, 255, 100 ) )
    bubble3:SetRenderMode( RENDERMODE_TRANSCOLOR )
    bubble3._bubbleScaleMult = -1
    table.insert( cosmeticBubbles, bubble3 )

    sound.Play( "ambient/levels/labs/electric_explosion1.wav", pos, 90, 110 )
    sound.Play( "ambient/fire/ignite.wav", pos, 90, 75, 0.5 )
    sound.Play( "ambient/machines/machine1_hit2.wav", pos, 90, 100 )

    return bubble, cosmeticBubbles
end

function ENT:BubbleStartTouch( ent )
    if not ent:IsPlayer() then return end
    if not ent:Alive() then return end

    -- Check if we're allowed to affect the player (there might be a build/pvp system, etc)
    local allowed = false

    hook.Add( "EntityTakeDamage", "CFC_PvPWeapons_AntiGravityGrenade_CheckIfDamageIsAllowed", function()
        allowed = true

        return true
    end, HOOK_LOW )

    local dmgInfo = DamageInfo()
    dmgInfo:SetAttacker( self:GetOwner() )
    dmgInfo:SetInflictor( self )
    dmgInfo:SetDamage( 100 )
    dmgInfo:SetDamageType( ent:InVehicle() and DMG_VEHICLE or DMG_GENERIC )

    ent:TakeDamageInfo( dmgInfo )
    hook.Remove( "EntityTakeDamage", "CFC_PvPWeapons_AntiGravityGrenade_CheckIfDamageIsAllowed" )

    if not allowed then return end

    -- Apply the effect
    ent:SetGravity( self.GravityMult )

    if ent:IsOnGround() then
        ent:SetVelocity( Vector( 0, 0, self.PushStrength ) )
    end

    ent._cfcPvPWeapons_AntiGravityGrenade = self

    sound.Play( "ambient/machines/machine1_hit2.wav", ent:EyePos(), 75, 120 )
    util.ScreenShake( ent:EyePos(), 3, 5, 1.5, 500, true, ent )

    return true
end

function ENT:BubbleTouch( ent )
    if ent:IsOnGround() then
        ent:SetVelocity( Vector( 0, 0, self.PushStrength ) )
    end
end

function ENT:BubbleEndTouch()
end

function ENT:BubbleEndEffect( ent )
    if not ent:IsPlayer() then return end

    -- Prevent grenades from resetting gravity early if the player quickly enters another one.
    local otherGrenade = ent._cfcPvPWeapons_AntiGravityGrenade
    if otherGrenade ~= self and IsValid( otherGrenade ) then return end

    ent:SetGravity( 1 )
    ent._cfcPvPWeapons_AntiGravityGrenade = nil
end

function ENT:PlayBeep()
    self:EmitSound( "npc/scanner/combat_scan4.wav", 75, 120 )
end
