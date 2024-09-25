AddCSLuaFile()

SWEP.Base = "cfc_discombob"
SWEP.PrintName = "Impact Discombob Grenade"
SWEP.Category = "CFC"

SWEP.Slot = 4
SWEP.Spawnable = true

SWEP.UseHands = true
SWEP.ViewModelFOV = 54
SWEP.ViewModel = Model( "models/weapons/cstrike/c_eq_fraggrenade.mdl" )
SWEP.WorldModel = Model( "models/weapons/w_eq_fraggrenade.mdl" )

SWEP.HoldType = "melee"

SWEP.Primary = {
    Ammo = "cfc_discomob",

    ThrowAct = { ACT_VM_PULLBACK_HIGH, ACT_VM_THROW },
    LobAct = { ACT_VM_PULLBACK_LOW, ACT_VM_HAULBACK },
    RollAct = { ACT_VM_PULLBACK_LOW, ACT_VM_SECONDARYATTACK },

    RadiusMult = 1, -- Affects the explosion radius
    StrengthMult = 1, -- Affects the knockback strengths
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

        ent.Radius = ent.Radius * radiusMult
        ent.Knockback = ent.Knockback * strengthMult
        ent.PlayerKnockback = ent.PlayerKnockback * strengthMult
        ent.PlayerSelfKnockback = ent.PlayerSelfKnockback * strengthMult

        local exploded = false

        function ent:PhysicsCollide()
            if exploded then return end

            exploded = true

            -- For some reason, running the explosion from inside the collision event causes the the player to lose health.
            timer.Simple( 0, function()
                if not IsValid( ent ) then return end

                ent:Explode()
            end )
        end

        return ent
    end
end
