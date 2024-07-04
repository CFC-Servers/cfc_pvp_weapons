AddCSLuaFile()

DEFINE_BASECLASS( "cfc_simple_base_throwing" )
SWEP.Base = "cfc_simple_base_throwing"

-- UI stuff

SWEP.PrintName = "Super Cinder Block"
SWEP.Category = "CFC"
SWEP.UseHands = true

SWEP.Slot = 1
SWEP.ViewModel = Model( "models/weapons/c_grenade.mdl" )
SWEP.Spawnable = true
SWEP.AdminOnly = true
SWEP.Instructions = "all bricked up"

SWEP.IdleHoldType = "slam"
SWEP.ThrowingHoldType = "melee"

SWEP.ProjectileClass = "cfc_cinderblock_projectile"
SWEP.InfiniteAmmo = true

SWEP.ModelScale = 1
SWEP.ModelMaterial = "models/weapons/cfc/gold_player"
SWEP.ThrowVelMul = 2

SWEP.WorldModel = "models/props_debris/concrete_cynderblock001.mdl"
SWEP.WMPosOffset = Vector( 8, 2, 0 )
SWEP.WMAngOffset = Angle( 0, 180, -90 )

SWEP.HeldModel = SWEP.WorldModel
SWEP.HeldModelPosOffset = Vector( -22, 8, -22 )
SWEP.HeldModelAngOffset = Angle( 0, -80, 0 )

SWEP.Primary.ThrowAct = { ACT_VM_PULLBACK_HIGH, ACT_VM_THROW }
SWEP.Primary.LobAct = { ACT_VM_PULLBACK_LOW, ACT_VM_HAULBACK }
SWEP.Primary.RollAct = { ACT_VM_PULLBACK_LOW, ACT_VM_SECONDARYATTACK }

SWEP.CFC_FirstTimeHints = {
    {
        Message = "Brick'em",
        Sound = "ambient/water/drip1.wav",
        Duration = 15,
    },
}

function SWEP:CreateEntity()
    local ent = ents.Create( self.ProjectileClass )
    ent:SetOwner( self:GetOwner() )
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