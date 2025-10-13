AddCSLuaFile()

DEFINE_BASECLASS( "cfc_simple_base_throwing" )
SWEP.Base = "cfc_simple_base_throwing"

-- UI stuff

SWEP.PrintName = "Super Cinder Block"
SWEP.Category = "CFC"
SWEP.UseHands = true

SWEP.AutoSwitchTo = true
SWEP.AutoSwitchFrom = false
SWEP.Weight = 1000
SWEP.Slot = 1
SWEP.ViewModel = Model( "models/weapons/c_grenade.mdl" )
SWEP.Spawnable = true
SWEP.AdminOnly = true
SWEP.Instructions = "It's just begging you to hit someone in the head!\nEventually despawns if not picked up."

if CLIENT then -- killicon, HUD icon and language 'translation'
    CFCPvPWeapons.CL_SetupSwep( SWEP, "cfc_super_cinder_block", "materials/vgui/hud/cfc_super_cinder_block.png" )
end

SWEP.IdleHoldType = "slam"
SWEP.ThrowingHoldType = "melee"

SWEP.ProjectileClass = "cfc_super_cinderblock_projectile"
SWEP.InfiniteAmmo = false

SWEP.ModelScale = 1
SWEP.ModelMaterial = "models/cfc/gold/gold_player"
SWEP.ThrowVelMul = 3

SWEP.WorldModel = "models/props_debris/concrete_cynderblock001.mdl"
SWEP.OffsetWorldModel = true
SWEP.WMPosOffset = Vector( 8, 2, 0 )
SWEP.WMAngOffset = Angle( 0, 180, -90 )

SWEP.HeldModel = SWEP.WorldModel
SWEP.HeldModelPosOffset = Vector( -22, 8, -22 )
SWEP.HeldModelAngOffset = Angle( 0, -80, 0 )

SWEP.Primary.ThrowAct = { ACT_VM_PULLBACK_HIGH, ACT_VM_THROW }
SWEP.Primary.LobAct = { ACT_VM_PULLBACK_LOW, ACT_VM_HAULBACK }
SWEP.Primary.RollAct = { ACT_VM_PULLBACK_LOW, ACT_VM_SECONDARYATTACK }

SWEP.AllowMultiplePickup = false

SWEP.DropOnDeath = true
SWEP.DropCleanupDelay = 240
SWEP.RetainAmmoOnDrop = false
SWEP.DoOwnerChangedEffects = true

SWEP.DoCollisionEffects = true
SWEP.HasFunHeavyPhysics = true

SWEP.IsCFCSuperCinderBlock = true

SWEP.CFC_FirstTimeHints = {
    {
        Message = "Brick'em",
        Sound = "ambient/water/drip1.wav",
        Duration = 15,
    },
}

function SWEP:CreateEntity()
    local ent = ents.Create( self.ProjectileClass )
    ent:SetThrower( self:GetOwner() )
    ent:Spawn()
    return ent
end

function SWEP:CustomAmmoDisplay()
    return { Draw = false }
end

function SWEP:EmitThrowSound()
    self:EmitSound( "WeaponFrag.Throw", 100, 70, 1, CHAN_STATIC, SND_CHANGE_PITCH )
    self:EmitSound( "WeaponFrag.Throw", 100, 40, 1, CHAN_STATIC, SND_CHANGE_PITCH )
    util.ScreenShake( self:WorldSpaceCenter(), 10, 20, 0.1, 1500 )
    util.ScreenShake( self:WorldSpaceCenter(), 20, 20, 0.5, 500 )
end

function SWEP:DropOnDeathFX( _owner )
    self:EmitSound( "physics/metal/metal_canister_impact_hard" .. math.random( 1, 3 ) .. ".wav", 90, math.random( 40, 50 ), 1, CHAN_STATIC )
end

function SWEP:OnPickedUpFX()
    self:EmitSound( "Canister.ImpactSoft", 80, math.random( 100, 110 ), 1, CHAN_STATIC, bit.bor( SND_CHANGE_PITCH, SND_CHANGE_VOL ) )
    self:EmitSound( "physics/metal/metal_canister_impact_hard" .. math.random( 1, 3 ) .. ".wav", 90, math.random( 30, 40 ), 0.5, CHAN_STATIC )
end

function SWEP:OnDroppedFX()
    self:EmitSound( "Canister.ImpactSoft", 80, math.random( 80, 90 ), 1, CHAN_STATIC, bit.bor( SND_CHANGE_PITCH, SND_CHANGE_VOL ) )
    self:EmitSound( "physics/metal/metal_canister_impact_hard" .. math.random( 1, 3 ) .. ".wav", 90, math.random( 20, 30 ), 0.5, CHAN_STATIC )
end

function SWEP:MakeCollisionEffectFunc()
    return function( ent, data )
        local nextSound = ent.cfcPvPWeapons_NextCollideSound or 0
        if nextSound > CurTime() then return end
        ent.cfcPvPWeapons_NextCollideSound = CurTime() + 0.05

        local speed = data.Speed
        if speed < 100 then return end

        local pitch = 180 - ( speed / 10 )
        ent:EmitSound( "Canister.ImpactSoft", 80, pitch, 1, CHAN_ITEM, bit.bor( SND_CHANGE_PITCH, SND_CHANGE_VOL ) )
        ent:EmitSound( "physics/metal/metal_canister_impact_hard" .. math.random( 1, 3 ) .. ".wav", 90, math.random( 40, 50 ), 0.5, CHAN_STATIC )

        local effectdata = EffectData()
        effectdata:SetOrigin( data.HitPos )
        effectdata:SetNormal( -data.HitNormal )
        effectdata:SetScale( 1 + speed / 2000 )
        effectdata:SetMagnitude( 1 )
        effectdata:SetRadius( speed / 10 )
        util.Effect( "Sparks", effectdata )
    end
end