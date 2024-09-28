AddCSLuaFile()

DEFINE_BASECLASS( "cfc_simple_base_throwing" )

if CLIENT then
    language.Add( "cfc_cluster_grenade_ammo", "Cluster Grenades" )
end

game.AddAmmoType( { name = "cfc_cluster_grenade", maxcarry = 5 } )

SWEP.Base = "cfc_simple_base_throwing"
SWEP.PrintName = "'Nade (Cluster)"
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

    SplitDelay = 0.25, -- Splits early mid-air.
    GrenadeOverrides = {
        Damage = 25,
        Radius = 200,
        ClusterAmount = 6,
        ClusterAmountMult = 0,
        ExplodeOnSplit = false,
        SplitLimit = false,
        SplitSpeed = 300,
        SplitSpread = 45,
        SplitMoveAhead = 0,
        BaseVelMultOnImpact = 0.25,
    },
}

SWEP.ThrowCooldown = 0


function SWEP:Initialize()
    self:SetMaterial( "models/weapons/w_models/cfc_frag_grenade/frag_grenade_cluster" )
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

        ent:SetTimer( self.Primary.SplitDelay )

        local entGrenadeParams = ent.GrenadeParams

        for k, v in pairs( self.Primary.GrenadeOverrides ) do
            entGrenadeParams[k] = v
        end

        return ent
    end
end
