AddCSLuaFile()

DEFINE_BASECLASS( "cfc_simple_base_throwing" )
SWEP.Base = "cfc_simple_base_throwing"

-- UI stuff

SWEP.PrintName = "Cinder Block"
SWEP.Category = "CFC"
SWEP.UseHands = true

if CLIENT then -- killicon, HUD icon and language 'translation'
    CFCPvPWeapons.CL_SetupSwep( SWEP, "cfc_cinder_block", "materials/vgui/hud/cfc_cinder_block.png" )
end

SWEP.Slot = 1
SWEP.ViewModel = Model( "models/weapons/c_grenade.mdl" )
SWEP.Spawnable = true
SWEP.Purpose = "Throw bricks at people!"
SWEP.Instructions = "More speed = more damage."

SWEP.IdleHoldType = "slam"
SWEP.ThrowingHoldType = "melee"

SWEP.ProjectileClass = "cfc_cinderblock_projectile"
SWEP.InfiniteAmmo = true

SWEP.ModelScale = 1
SWEP.ModelMaterial = nil
SWEP.ThrowVelMul = 0.25

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
    self:EmitSound( "WeaponFrag.Throw", 75, 70, 1, CHAN_WEAPON, SND_CHANGE_PITCH )
end