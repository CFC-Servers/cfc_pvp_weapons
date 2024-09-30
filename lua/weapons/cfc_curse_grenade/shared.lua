AddCSLuaFile()

if CLIENT then
    language.Add( "cfc_curse_grenade_ammo", "Curse Grenades" )
end

game.AddAmmoType( { name = "cfc_curse_grenade", maxcarry = 5 } )

SWEP.Base = "cfc_simple_base_throwing"
SWEP.PrintName = "'Nade (Curse)"
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
    Ammo = "cfc_curse_grenade",

    ThrowAct = { ACT_VM_PULLBACK_HIGH, ACT_VM_THROW },
    LobAct = { ACT_VM_PULLBACK_LOW, ACT_VM_HAULBACK },
    RollAct = { ACT_VM_PULLBACK_LOW, ACT_VM_SECONDARYATTACK },
}


function SWEP:Initialize()
    self:SetMaterial( "models/weapons/w_models/cfc_frag_grenade/frag_grenade_curse" )
end


if SERVER then
    function SWEP:CreateEntity()
        if not CFCUlxCurse then
            self:GetOwner():ChatPrint( "This server doesn't have the CFC ulx curse addon!" )

            return
        end

        local ent = ents.Create( "cfc_simple_ent_curse_grenade" )
        local ply = self:GetOwner()

        ent:SetPos( ply:GetPos() )
        ent:SetAngles( ply:EyeAngles() )
        ent:SetOwner( ply )
        ent:Spawn()
        ent:Activate()

        ent:SetTimer( 3 )

        return ent
    end
end
