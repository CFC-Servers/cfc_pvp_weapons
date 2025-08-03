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
    CFCPvPWeapons.CL_SetupSent( ENT, "cfc_super_cinderblock_projectile", "materials/vgui/hud/cfc_super_cinder_block.png" )
end

ENT.Model = Model( "models/props_debris/concrete_cynderblock001.mdl" )
ENT.ModelScale = 1

ENT.BaseDamage = 500
ENT.AdditionalDamageStartingVel = 500
ENT.VelocityForOneDamage = 100
ENT.DamageForceMul = 5

ENT.HullSize = 10

-- just a cache
ENT.HullVec = Vector( ENT.HullSize, ENT.HullSize, ENT.HullSize )

function ENT:HitEffects( _, _, speed )
    local pitch = 180 - ( speed / 30 )

    self:EmitSound( "Concrete_Block.ImpactHard", 70, pitch, 1, CHAN_STATIC, bit.bor( SND_CHANGE_PITCH, SND_CHANGE_VOL ) )
    self:EmitSound( "physics/concrete/concrete_impact_hard3.wav", 70, 40, 1, CHAN_STATIC )
end

local vec_up = Vector( 0, 0, 1 )
local criticalDamage = 100

function ENT:PostHitEnt( hitEnt, damageDealt )

    util.ScreenShake( self:WorldSpaceCenter(), 5 + ( damageDealt * 0.5 ), 20, 0.5, 500 + damageDealt * 2 )
    util.ScreenShake( self:WorldSpaceCenter(), 5, 20, 0.1, 1500 + damageDealt )

    if not ( hitEnt:IsPlayer() or hitEnt:IsNPC() ) then return end
    if damageDealt >= criticalDamage then
        hitEnt:EmitSound( "Flesh.ImpactHard", 90, 70, 1, CHAN_STATIC )
        hitEnt:EmitSound( "Breakable.MatFlesh", 90, 70, 1, CHAN_STATIC )
        hitEnt:EmitSound( "player/pl_fallpain1.wav", 95, 80, 1, CHAN_STATIC )
        hitEnt:EmitSound( "npc/antlion/shell_impact4.wav", 95, math.random( 20, 30 ), 1, CHAN_STATIC )

    end
end
function ENT:PostHit( hitEnt, _pos, _normal, _speed, damageDealt )
    local block = ents.Create( "cfc_super_cinder_block" )

    if IsValid( block ) then
        block.cfcsupercinderblock_nextpickup = CurTime() + 1.25
        block:SetPos( self:GetPos() -self:GetVelocity():GetNormalized() * 10 )
        block:SetAngles( self:GetAngles() )
        block:SetModel( self.Model )
        block:SetMaterial( self:GetMaterial() )
        block:Spawn()

        local blocksObj = block:GetPhysicsObject()

        if damageDealt >= criticalDamage then
            -- kinda unsatisfying sounds when you just hit something
            -- combines well with below on great hits
            block:EmitSound( "physics/metal/metal_canister_impact_hard2.wav", 90, math.random( 10, 15 ), 1, CHAN_STATIC )
            block:EmitSound( "physics/metal/metal_box_impact_bullet" .. math.random( 1, 3 ) .. ".wav", 90, math.random( 30, 40 ), 0.5, CHAN_STATIC )

        end
        if damageDealt >= criticalDamage and IsValid( hitEnt ) and hitEnt:GetMaxHealth() >= 10 then
            blocksObj:SetVelocity( vec_up * damageDealt * 1 )
            blocksObj:ApplyTorqueCenter( vec_up * damageDealt * 2 )

            -- deep thwap when you hit something good
            block:EmitSound( "physics/metal/metal_box_impact_bullet" .. math.random( 1, 3 ) .. ".wav", 90, math.random( 10, 20 ), 1, CHAN_STATIC )

        else
            blocksObj:SetVelocity( self:GetVelocity() / 2 )

        end
    end
end