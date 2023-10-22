SWEP.Base = "cfc_simple_base_throwing"
SWEP.PrintName = "Void Grenade"
SWEP.Category = "CFC"
SWEP.IconOverride = "materials/entities/weapon_frag.png"

SWEP.Slot = 4
SWEP.Spawnable = true
SWEP.UseHands = true

SWEP.ViewModelFOV = 54
SWEP.ViewModel = Model( "models/weapons/c_grenade.mdl" )
SWEP.WorldModel = Model( "models/weapons/w_grenade.mdl" )

SWEP.Primary.Ammo = "grenade"

if SERVER then
    function SWEP:CreateEntity()
        local ent = ents.Create( "cfc_void" )
        local ply = self:GetOwner()
        ent:SetPos( ply:GetPos() )
        ent:SetAngles( ply:EyeAngles() )
        ent:SetOwner( ply )
        ent:Spawn()
        ent:Activate()

        return ent
    end
end
