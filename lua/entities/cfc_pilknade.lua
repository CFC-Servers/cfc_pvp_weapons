AddCSLuaFile()
DEFINE_BASECLASS( "cfc_simple_ent_grenade_base" )
ENT.Base = "cfc_simple_ent_grenade_base"
ENT.Model = Model( "models/weapons/w_npcnade.mdl" )
ENT.Damage = 300
ENT.ExplodeTime = 2

ENT.Trail = true
ENT.TrailColor = "255 255 255"

function ENT:Explode()
    local pos = self:WorldSpaceCenter()
    local effectdata = EffectData()
    effectdata:SetOrigin( pos )
    util.Effect( "WaterSurfaceExplosion", effectdata )

    self:Remove()
end
