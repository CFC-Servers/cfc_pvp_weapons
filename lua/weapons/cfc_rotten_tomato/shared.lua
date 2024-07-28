AddCSLuaFile()

DEFINE_BASECLASS( "cfc_simple_base_throwing" )
SWEP.Base = "cfc_simple_base_throwing"

-- UI stuff

SWEP.PrintName = "Rotten Tomato"
SWEP.Category = "CFC"
SWEP.UseHands = true

SWEP.Slot = 1
SWEP.ViewModel = Model( "models/weapons/c_grenade.mdl" )
SWEP.Spawnable = true
SWEP.Instructions = "Splat!"

SWEP.ProjectileClass = "cfc_rotten_tomato_projectile"
SWEP.InfiniteAmmo = true

SWEP.ModelScale = 0.5
SWEP.ModelMaterial = "models/weapons/cfc/tomato"

SWEP.WorldModel = "models/props_junk/watermelon01.mdl"
SWEP.WMPosOffset = Vector( -1, 2, 0 )
SWEP.WMAngOffset = Angle( 0, 180, -90 )

SWEP.HeldModel = SWEP.WorldModel
SWEP.HeldModelPosOffset = Vector( -22, 3, -22 )
SWEP.HeldModelAngOffset = Angle( 0, 0, -180 )

SWEP.Primary.ThrowAct = { ACT_VM_PULLBACK_HIGH, ACT_VM_THROW }
SWEP.Primary.LobAct = { ACT_VM_PULLBACK_LOW, ACT_VM_HAULBACK }
SWEP.Primary.RollAct = { ACT_VM_PULLBACK_LOW, ACT_VM_SECONDARYATTACK }

function SWEP:CreateEntity()
    local ent = ents.Create( self.ProjectileClass )
    ent:SetCreator( self:GetOwner() )
    ent:Spawn()
    return ent
end

function SWEP:CustomAmmoDisplay()
    return { Draw = false }
end