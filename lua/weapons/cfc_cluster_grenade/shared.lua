AddCSLuaFile()

if CLIENT then
    language.Add( "cfc_cluster_grenade_ammo", "Cluster Grenades" )
end

game.AddAmmoType( { name = "cfc_cluster_grenade", maxcarry = 5 } )

SWEP.Base = "cfc_simple_base_throwing"
SWEP.PrintName = "Cluster Grenade"
SWEP.Category = "CFC"

SWEP.Slot = 4
SWEP.Spawnable = true

SWEP.UseHands = true
SWEP.ViewModelFOV = 54
SWEP.ViewModel = Model( "models/weapons/cstrike/c_eq_fraggrenade.mdl" )
SWEP.WorldModel = Model( "models/weapons/w_eq_fraggrenade.mdl" )

SWEP.HoldType = "melee"

SWEP.Primary = {
    Ammo = "cfc_cluster_grenade",

    ThrowAct = { ACT_VM_PULLBACK_HIGH, ACT_VM_THROW },
    LobAct = { ACT_VM_PULLBACK_LOW, ACT_VM_HAULBACK },
    RollAct = { ACT_VM_PULLBACK_LOW, ACT_VM_SECONDARYATTACK },

    SplitDelay = 0.25, -- Primary fire only splits on impact, secondary splits either mid-air or on impact.
}


function SWEP:Initialize()
    self:SetMaterial( "models/weapons/w_models/cfc_frag_grenade/frag_grenade_cluster" )
end

function SWEP:PrimaryAttack()
    if not self:CanThrow() then return end

    self:SetThrowMode( 1 )
    self:SetFinishThrow( CurTime() + self:SendTranslatedWeaponAnim( self.Primary.ThrowAct[1] ) )
    self:SetNextIdle( 0 )

    self:SetHoldType( self.HoldType )

    self._cluster_splitMidair = false
end

function SWEP:SecondaryAttack()
    if not self:CanThrow() then return end

    self:SetThrowMode( 1 )
    self:SetFinishThrow( CurTime() + self:SendTranslatedWeaponAnim( self.Primary.ThrowAct[1] ) )
    self:SetNextIdle( 0 )

    self:SetHoldType( self.HoldType )

    self._cluster_splitMidair = true
end


if SERVER then
    function SWEP:CreateEntity()
        local ent = ents.Create( "cfc_simple_ent_cluster_grenade" )
        local ply = self:GetOwner()

        ent:SetPos( ply:GetPos() )
        ent:SetAngles( ply:EyeAngles() )
        ent:SetOwner( ply )
        ent:Spawn()
        ent:Activate()

        if self._cluster_splitMidair then
            ent:SetTimer( self.Primary.SplitDelay )
        end

        return ent
    end
end
