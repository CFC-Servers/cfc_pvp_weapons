AddCSLuaFile()

DEFINE_BASECLASS( "cfc_simple_base_throwing" )
SWEP.Base = "cfc_simple_base_throwing"

-- UI stuff

SWEP.PrintName = "Stone"
SWEP.Category = "CFC"
SWEP.UseHands = true

if CLIENT then -- killicon, HUD icon and language 'translation'
    CFCPvPWeapons.CL_SetupSwep( SWEP, "cfc_stone", "materials/vgui/hud/cfc_stone.png" )
end

SWEP.Slot = 1
SWEP.ViewModel = Model( "models/weapons/c_grenade.mdl" )
SWEP.Spawnable = true
SWEP.Purpose = "Throw rocks at people!"
SWEP.Instructions = "Aim for the head!"

SWEP.IdleHoldType = "slam"
SWEP.ThrowingHoldType = "melee"

SWEP.ProjectileClass = "cfc_stone_projectile"
SWEP.InfiniteAmmo = true

SWEP.ModelScale = 0.5
SWEP.ModelMaterial = nil
SWEP.ThrowVelMul = 0.85

SWEP.WorldModel = "models/props_junk/rock001a.mdl"
SWEP.OffsetWorldModel = true
SWEP.WMPosOffset = Vector( 0, 2, 0 )
SWEP.WMAngOffset = Angle( 0, 180, -90 )

SWEP.HeldModel = SWEP.WorldModel
SWEP.HeldModelPosOffset = Vector( -22, 1.5, -21 )
SWEP.HeldModelAngOffset = Angle( 0, 0, 0 )

function SWEP:EmitThrowSound()
    self:EmitSound( "WeaponFrag.Throw", 75, 120, 1, CHAN_WEAPON, SND_CHANGE_PITCH )
end

function SWEP:CreateEntity()
    local ent = ents.Create( self.ProjectileClass )
    ent:SetThrower( self:GetOwner() )
    ent:Spawn()
    return ent
end

function SWEP:CustomAmmoDisplay()
    return { Draw = false }
end