AddCSLuaFile()

if CLIENT then
    language.Add( "cfc_discomob_ammo", "Discombobs" )
end

game.AddAmmoType( { name = "cfc_discomob", maxcarry = 5 } )

SWEP.Base = "cfc_simple_base_throwing"
SWEP.PrintName = "'Nade (Discombob)"
SWEP.Category = "CFC"

SWEP.Slot = 4
SWEP.Spawnable = true

SWEP.UseHands = true
SWEP.ViewModelFOV = 54
SWEP.ViewModel = Model( "models/weapons/cstrike/c_eq_fraggrenade.mdl" ) -- Funnily enough, both of these are in the gmod vpk.
SWEP.WorldModel = Model( "models/weapons/w_eq_fraggrenade.mdl" ) -- However, the worldmodel's material is not packed, while the viewmodel's material is. Hence it being set in Initialize.

SWEP.HoldType = "melee"

SWEP.Primary = {
    Ammo = "cfc_discomob",

    ThrowAct = { ACT_VM_PULLBACK_HIGH, ACT_VM_THROW },
    LobAct = { ACT_VM_PULLBACK_LOW, ACT_VM_HAULBACK },
    RollAct = { ACT_VM_PULLBACK_LOW, ACT_VM_SECONDARYATTACK },

    RadiusMult = 1.25, -- Affects the explosion radius
    StrengthMult = 1.25, -- Affects the knockback strength against other players and props
    StrengthMultSelf = 1.25, -- Affects the knockback strength against the player who threw it
}


function SWEP:Initialize()
    self:SetMaterial( "models/weapons/w_models/cfc_frag_grenade/frag_grenade_discombob" )
end


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
        local strengthMultSelf = self.Primary.StrengthMultSelf

        ent.Radius = ent.Radius * radiusMult
        ent.Knockback = ent.Knockback * strengthMult
        ent.PlayerKnockback = ent.PlayerKnockback * strengthMult
        ent.PlayerSelfKnockback = ent.PlayerSelfKnockback * strengthMultSelf

        return ent
    end
end
