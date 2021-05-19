AddCSLuaFile()
-- General info
SWEP.Author = "Redox"
SWEP.Contact = "CFC Discord"
SWEP.Purpose = "Tazing players and npcs."
SWEP.Base = "weapon_base"
SWEP.PrintName = "Tazer"
SWEP.Instructions = "Left click to tazer the target."
SWEP.Category = "CFC"
-- Visuals
SWEP.ViewModel = "models/weapons/c_pistol.mdl"
SWEP.WorldModel = "models/weapons/w_pistol.mdl"
SWEP.UseHands = true
SWEP.SetHoldType = "pistol"
SWEP.DrawAmmo = false
SWEP.DrawCrosshair = true
-- Functionals
SWEP.Slot = 1
SWEP.SlotPos = 1
SWEP.Spawnable = true
SWEP.AdminSpawnable = true
SWEP.AdminOnly = false
-- Ammo and such
-- Primary
SWEP.Primary.ClipSize = 1
SWEP.Primary.DefaultClip = 20
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "Pistol"
-- Secondary
SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = true
SWEP.Secondary.Ammo = ""

function SWEP:Reload()
    self:DefaultReload(ACT_VM_RELOAD)
end

--local  pos = ply:getShootPos() + ( ply:getEyeAngles():getForward() * 100)
function SWEP:PrimaryAttack()
end