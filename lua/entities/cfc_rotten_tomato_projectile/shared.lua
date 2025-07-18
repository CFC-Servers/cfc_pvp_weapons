-- also a baseclass for projectiles that fly slow, and deal bullet-like damage on impact

ENT.Type = "anim"
ENT.Base = "base_anim"

ENT.PrintName       = "Rotten Tomato"
ENT.Author          = "StrawWagen"
ENT.Contact         = ""
ENT.Purpose         = "Splat!."
ENT.Instructions    = "Splat!!."
ENT.Spawnable       = false

if CLIENT then -- killicon, and language 'translation'
    CFCPvPWeapons.CL_SetupSent( ENT, "cfc_rotten_tomato_projectile", "materials/vgui/hud/cfc_rotten_tomato.png" )
end

ENT.Model = Model( "models/props_junk/watermelon01.mdl" )
ENT.ModelScale = 0.5

ENT.BaseDamage = 1
ENT.AdditionalDamageStartingVel = 1200
ENT.VelocityForOneDamage = 83
ENT.DamageForceMul = 1

ENT.HullSize = 2

-- just a cache
ENT.HullVec = Vector( ENT.HullSize, ENT.HullSize, ENT.HullSize )

function ENT:SetupDataTables()
    self:NetworkVar( "Entity", "Thrower" ) -- cant use owner because its reset so we can collide with the thrower
end