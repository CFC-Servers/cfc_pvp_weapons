ENT.Type = "anim"
ENT.Base = "base_anim"

ENT.PrintName       = "Rotten Tomato"
ENT.Author          = "StrawWagen"
ENT.Contact         = ""
ENT.Purpose         = "Splat!."
ENT.Instructions    = "Splat!!."
ENT.Spawnable       = false

ENT.Model = Model( "models/props_junk/watermelon01.mdl" )
ENT.ModelScale = 0.5

ENT.BaseDamage = 1
ENT.AdditionalDamageStartingVel = 1200
ENT.VelocityForOneDamage = 83

ENT.HullSize = 2

-- just a cache
ENT.HullVec = Vector( ENT.HullSize, ENT.HullSize, ENT.HullSize )