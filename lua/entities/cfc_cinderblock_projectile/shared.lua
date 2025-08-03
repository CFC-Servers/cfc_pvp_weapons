AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "cfc_rotten_tomato_projectile"

ENT.PrintName       = "Cinder Block"
ENT.Author          = "StrawWagen"
ENT.Contact         = ""
ENT.Purpose         = "Look out below!."
ENT.Instructions    = "Drop off of buildings."
ENT.Spawnable       = false

if CLIENT then -- killicon, and language 'translation'
    CFCPvPWeapons.CL_SetupSent( ENT, "cfc_cinderblock_projectile", "materials/vgui/hud/cfc_cinder_block.png" )
end

ENT.Model = Model( "models/props_debris/concrete_cynderblock001.mdl" )
ENT.ModelScale = 1

ENT.BaseDamage = 35
ENT.AdditionalDamageStartingVel = 500
ENT.VelocityForOneDamage = 8

ENT.HullSize = 10

-- just a cache
ENT.HullVec = Vector( ENT.HullSize, ENT.HullSize, ENT.HullSize )


local vec_up = Vector( 0, 0, 1 )
local criticalDamage = 50

function ENT:PostHitEnt( hitEnt, damageDealt, actuallyDidDamage )
    util.ScreenShake( self:WorldSpaceCenter(), 5 + ( damageDealt * 0.5 ), 20, 0.5, 500 + damageDealt * 2 )
    util.ScreenShake( self:WorldSpaceCenter(), 5, 20, 0.1, 1500 + damageDealt )

    if not actuallyDidDamage then return end
    if hitEnt:IsPlayer() and self:WorldSpaceCenter():Distance( hitEnt:GetShootPos() ) < 25 then -- easy headshot check
        self:DoMotionBlur( hitEnt, damageDealt )
    end
    if not ( hitEnt:IsPlayer() or hitEnt:IsNPC() ) then return end
    if damageDealt >= criticalDamage then
        self:EmitSound( "physics/concrete/concrete_block_impact_hard" .. math.random( 1, 3 ) .. ".wav", 90, math.random( 40, 50 ), 1, CHAN_STATIC )
        self:EmitSound( "Flesh.ImpactHard", 90, 70, 1, CHAN_STATIC )
        self:EmitSound( "Breakable.MatFlesh", 90, 70, 1, CHAN_STATIC )
    end
end

function ENT:PostHit( _hitEnt, _pos, _normal, speed, damageDealt, _actuallyDidDamage )
    if not IsValid( self ) then return end

    local pitch = 180 - ( speed / 25 )

    self:EmitSound( "Concrete_Block.ImpactHard", 70, pitch, 1, CHAN_STATIC, bit.bor( SND_CHANGE_PITCH, SND_CHANGE_VOL ) )
    self:EmitSound( "physics/concrete/concrete_block_impact_hard2.wav", 70, 80, 1, CHAN_STATIC )

    local gib = ents.Create( "prop_physics" )

    if IsValid( gib ) then
        gib:SetCollisionGroup( COLLISION_GROUP_WEAPON )
        gib:SetPos( self:GetPos() -self:GetVelocity():GetNormalized() * 10 )
        gib:SetAngles( self:GetAngles() )
        gib:SetModel( self.Model )
        gib:SetMaterial( self:GetMaterial() )
        gib:SetModelScale( self.ModelScale, 0 )
        gib:Spawn()

        local gibsObj = gib:GetPhysicsObject()

        if damageDealt >= criticalDamage then
            gibsObj:SetVelocity( vec_up * damageDealt * 2 )
            gibsObj:ApplyTorqueCenter( vec_up * damageDealt * 2 )
        else
            gibsObj:SetVelocity( self:GetVelocity() / 2 )
        end

        SafeRemoveEntityDelayed( gib, 5 )
    end
end

-- concussion
function ENT:DoMotionBlur( hitEnt, damageDealt )
    delay = damageDealt / 50

    if delay < 0.05 then
        return
    end

    alphaAdd = 0.5

    hitEnt:ConCommand( "pp_motionblur 1" )
    hitEnt:ConCommand( "pp_motionblur_addalpha" .. alphaAdd )
    hitEnt:ConCommand( "pp_motionblur_drawalpha" .. alphaAdd )
    hitEnt:ConCommand( "pp_motionblur_delay" .. delay )

    -- ramp down the delay and disable the effect when it runs out
    timerName = "cfc_cinderblock_concussioncleanup_" .. hitEnt:GetCreationID()
    timer.Create( timerName, 0.25, 0, function()
        if not IsValid( hitEnt ) then
            timer.Remove( timerName )
            return
        end

        delay = delay - 0.05
        alphaAdd = alphaAdd - 0.05

        if delay <= 0 or not hitEnt:Alive() then
            hitEnt:ConCommand( "pp_motionblur 0" )
            hitEnt:ConCommand( "pp_motionblur_delay " .. 0 )
            timer.Remove( timerName )
            return
        end

        hitEnt:ConCommand( "pp_motionblur_addalpha " .. alphaAdd )
        hitEnt:ConCommand( "pp_motionblur_drawalpha " .. alphaAdd )
        hitEnt:ConCommand( "pp_motionblur_delay " .. delay )
    end )
end