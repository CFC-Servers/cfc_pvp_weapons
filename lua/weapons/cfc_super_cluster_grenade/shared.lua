AddCSLuaFile()

DEFINE_BASECLASS( "cfc_simple_base_throwing" )

if CLIENT then
    language.Add( "cfc_super_cluster_grenade_ammo", "Super Cluster Grenades" )
end

game.AddAmmoType( { name = "cfc_super_cluster_grenade", maxcarry = 5 } )

SWEP.Base = "cfc_simple_base_throwing"
SWEP.PrintName = "Super 'Nade (Cluster)"
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
        Damage = 25,
        Radius = 250,
        ClusterAmount = 8,
        ClusterAmountMult = 4 / 8,
        ExplodeOnSplit = true,
        SplitLimit = false,
        SplitSpeed = 300,
        SplitSpread = 50,
        SplitMoveAhead = 0,
        BaseVelMultOnImpact = 0.25,
        ExplosionPitch = 70,
    },
    GrenadeOverridesSplitMidAir = {
        Damage = 25,
        Radius = 200,
        ClusterAmount = 6,
        ClusterAmountMult = 3 / 6,
        ExplodeOnSplit = true,
        SplitLimit = false,
        SplitSpeed = 300,
        SplitSpread = 60,
        SplitMoveAhead = 0,
        BaseVelMultOnImpact = 0.25,
        ExplosionPitch = 70,
    },
}

SWEP.ThrowCooldown = 1

SWEP.CFC_FirstTimeHints = {
    {
        Message = "Press reload (R) to toggle the grenades splitting mid-air.",
        Sound = "ambient/water/drip1.wav",
        Duration = 7,
        DelayNext = 0,
    },
}


function SWEP:SetupDataTables()
    BaseClass.SetupDataTables( self )

    self:AddNetworkVar( "Bool", "MidAirSplit" )
end

function SWEP:Initialize()
    self:SetMaterial( "models/weapons/w_models/cfc_frag_grenade/frag_grenade_cluster" )
end

function SWEP:Reload()
    if CLIENT then return end

    local nextReloadTime = self._getNextReloadTime or 0
    local now = CurTime()
    if nextReloadTime > now then return end

    self._getNextReloadTime = now + 0.5

    self:SetMidAirSplit( not self:GetMidAirSplit() )
    sound.Play( "doors/handle_pushbar_locked1.wav", self:GetOwner():EyePos(), 75, 130, 1 )
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

        if self:GetMidAirSplit() then
            ent:SetTimer( self.Primary.SplitDelay )

            local entGrenadeParams = ent.GrenadeParams

            for k, v in pairs( self.Primary.GrenadeOverridesSplitMidAir ) do
                entGrenadeParams[k] = v
            end
        else
            local entGrenadeParams = ent.GrenadeParams

            for k, v in pairs( self.Primary.GrenadeOverrides ) do
                entGrenadeParams[k] = v
            end
        end

        return ent
    end
else
    function SWEP:CustomAmmoDisplay()
        return {
            Draw = true,
            PrimaryClip = self:GetOwner():GetAmmoCount( self.Primary.Ammo ),
            SecondaryAmmo = self:GetMidAirSplit() and 1 or nil,
        }
    end
end
