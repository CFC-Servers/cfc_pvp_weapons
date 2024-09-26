AddCSLuaFile()

DEFINE_BASECLASS( "cfc_cluster_grenade" )

if CLIENT then
    language.Add( "cfc_super_cluster_grenade_ammo", "Super Cluster Grenades" )
end

game.AddAmmoType( { name = "cfc_super_cluster_grenade", maxcarry = 5 } )

SWEP.Base = "cfc_cluster_grenade"
SWEP.PrintName = "Super Cluster Nade"
SWEP.Category = "CFC"

SWEP.Slot = 4
SWEP.Spawnable = true
SWEP.AdminOnly = true

SWEP.UseHands = true
SWEP.ViewModelFOV = 54
SWEP.ViewModel = Model( "models/weapons/cstrike/c_eq_fraggrenade.mdl" )
SWEP.WorldModel = Model( "models/weapons/w_eq_fraggrenade.mdl" )

SWEP.HoldType = "melee"

SWEP.Primary = {
    Ammo = "cfc_super_cluster_grenade",

    ThrowAct = { ACT_VM_PULLBACK_HIGH, ACT_VM_THROW },
    LobAct = { ACT_VM_PULLBACK_LOW, ACT_VM_HAULBACK },
    RollAct = { ACT_VM_PULLBACK_LOW, ACT_VM_SECONDARYATTACK },

    SplitDelay = 0.25, -- Reload toggles between only splitting on impact and splitting either mid-air or on impact.
    GrenadeOverrides = {
        Damage = 20,
        Radius = 200,
        ClusterAmount = 6,
        ClusterAmountMult = 5 / 10,
        ExplodeOnSplit = true,
        SplitLimit = false,
        SplitSpeed = 300,
        SplitSpread = 50,
        SplitMoveAhead = 0,
        BaseVelMultOnImpact = 0.25,
        ExplosionPitch = 70,
    },
    GrenadeOverridesSplitMidAir = {
        Damage = 20,
        Radius = 150,
        ClusterAmount = 6,
        ClusterAmountMult = 5 / 10,
        ExplodeOnSplit = true,
        SplitLimit = false,
        SplitSpeed = 300,
        SplitSpread = 60,
        SplitMoveAhead = 0,
        BaseVelMultOnImpact = 0.25,
        ExplosionPitch = 70,
    },
}
