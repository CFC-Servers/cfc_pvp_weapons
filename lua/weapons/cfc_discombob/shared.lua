AddCSLuaFile()

if CLIENT then
    language.Add( "cfc_discomob_ammo", "Discombob Grenades" )
end

game.AddAmmoType( { name = "cfc_discomob", maxcarry = 5 } )

SWEP.Base = "cfc_simple_base_throwing"
SWEP.PrintName = "Discombob Grenade"
SWEP.Category = "CFC"

SWEP.Slot = 4
SWEP.Spawnable = true

SWEP.UseHands = true
SWEP.ViewModelFOV = 54
SWEP.ViewModel = Model( "models/weapons/cstrike/c_eq_fraggrenade.mdl" ) -- Funnily enough, both of these are in the gmod vpk.
SWEP.WorldModel = Model( "models/weapons/w_eq_fraggrenade.mdl" )

SWEP.HoldType = "melee"

SWEP.Primary = {
    Ammo = "cfc_discomob",

    ThrowAct = { ACT_VM_PULLBACK_HIGH, ACT_VM_THROW },
    LobAct = { ACT_VM_PULLBACK_LOW, ACT_VM_HAULBACK },
    RollAct = { ACT_VM_PULLBACK_LOW, ACT_VM_SECONDARYATTACK },

    RadiusMult = 1.25, -- Affects the explosion radius
    StrengthMult = 1.25, -- Affects the knockback strengths
}

if SERVER then
    function SWEP:CreateEntity()
        local ent = ents.Create( "cfc_simple_ent_discombob" )
        local ply = self:GetOwner()

        ent:SetPos( ply:GetPos() )
        ent:SetAngles( ply:EyeAngles() )
        ent:SetOwner( ply )
        ent:Spawn()
        ent:Activate()

        ent:SetTimer( 3 )

        local radiusMult = self.Primary.RadiusMult
        local strengthMult = self.Primary.StrengthMult

        ent.Radius = ent.Radius * radiusMult
        ent.Knockback = ent.Knockback * strengthMult
        ent.PlayerKnockback = ent.PlayerKnockback * strengthMult
        ent.PlayerSelfKnockback = ent.PlayerSelfKnockback * strengthMult

        return ent
    end
end
