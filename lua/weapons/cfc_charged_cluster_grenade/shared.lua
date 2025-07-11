AddCSLuaFile()

DEFINE_BASECLASS( "cfc_charged_throwable" )

SWEP.Base = "cfc_charged_throwable"
SWEP.PrintName = "'Nade (Charged Cluster)"
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

    ChargeGap = 0.7, -- The gap between charge steps.
    ChargeStep = 1, -- Amount of charge to add per step. Must be an integer.
    ChargeMax = 5, -- Maximum charge.

    ChargeSound = "npc/dog/dog_idlemode_loop1.wav", -- Should be a looping sound
    ChargeVolume = 1,
    ChargeStepSound = "doors/handle_pushbar_locked1.wav",
    ChargeStepVolume = 1,
    ChargeStepPitchMinStart = 80,
    ChargeStepPitchMaxStart = 120,
    ChargeStepPitchMinEnd = 255,
    ChargeStepPitchMaxEnd = 255,
    ChargeStepPitchEase = function( x ) return x end, -- Use an easing function (e.g. math.ease.InCubic). Default is linear, which isn't in the ease library.

    GrenadeOverrides = {
        Damage = 25,
        Radius = 250,
        --ClusterAmount = 1, -- Dynamically set to the value of charge.
        ClusterAmountMult = 1,
        ExplodeOnSplit = false,
        SplitLimit = 2,
        SplitSpeed = 300,
        SplitSpread = 50,
        SplitMoveAhead = 0,
        BaseVelMultOnImpact = 0.25,
    },
}

SWEP.ThrowCooldown = 0

SWEP.CFC_FirstTimeHints = {
    {
        Message = "The Charged Cluster Grenade is a charged weapon. Hold left mouse before releasing to make it stronger.",
        Sound = "ambient/water/drip1.wav",
        Duration = 7,
        DelayNext = 0,
    },
}


function SWEP:Initialize()
    self:SetMaterial( "models/weapons/w_models/cfc_frag_grenade/frag_grenade_cluster" )
end

if SERVER then
    function SWEP:CreateEntity()
        local ent = ents.Create( "cfc_simple_ent_cluster_grenade" )
        local ply = self:GetOwner()
        local pos = ply:GetPos()

        ent:SetPos( pos )
        ent:SetAngles( ply:EyeAngles() )
        ent:SetOwner( ply )
        ent:Spawn()
        ent:Activate()

        local entGrenadeParams = ent.GrenadeParams
        local grenadeOverrides = self.Primary.GrenadeOverrides
        local charge = self:GetCharge()

        grenadeOverrides.ClusterAmount = charge

        for k, v in pairs( grenadeOverrides ) do
            entGrenadeParams[k] = v
        end

        if charge < 2 then
            entGrenadeParams.SplitLimit = 1
        end

        ent:EmitSound( "npc/scanner/scanner_nearmiss1.wav", 90, 120, 1 )

        return ent
    end
end
