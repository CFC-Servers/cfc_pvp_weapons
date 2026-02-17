SWEP.Base = "cfc_prsbox_zaza"
DEFINE_BASECLASS( SWEP.Base )

SWEP.Author = "CFC"

SWEP.Category = "CFC"
SWEP.PrintName = "Super Zaza"
SWEP.Spawnable = true
SWEP.AdminOnly = true

local sThisEntClass = "cfc_prsbox_super_zaza"

if CLIENT then
	CFCPvPWeapons.CL_SetupSwep( SWEP, sThisEntClass, "materials/entities/" .. sThisEntClass .. ".png" )
end

SWEP.LongestTime = 10
SWEP.ExhaleTime = 3.5

-- heals to 1500 HP
SWEP.HealthPerExhale = 750
SWEP.MaxHealth = 1500

SWEP.BlackoutAlpha = 0
SWEP.FadeInSpeed = 100
SWEP.FadeOutSpeed = 35
SWEP.ModelScale = 4

if not CLIENT then return end

local alpha = 0

SWEP.OnStartDrawingHud = function()
	alpha = 0
end

SWEP.DrawHudFunc = function( self )
	local speed = self:GetUse() and self.FadeInSpeed or self.FadeOutSpeed
	alpha = math.Approach( alpha, self:GetUse() and 255 or 0, FrameTime() * speed )

	if alpha <= 0 and not self:GetUse() then return false end

	surface.SetMaterial( self.VignetteMaterial )

	surface.SetDrawColor( 255, 255, 255, alpha )
	for _ = 1, 3 do
		surface.DrawTexturedRect( -1, -1, ScrW() + 1, ScrH() + 1 )
	end

	-- fade to black when holding too long
	local smokeTime = self:GetSmoke()
	local blackoutStart = self.LongestTime * 0.5 -- Start fading to black at 50% of max hold time
	local targetAlpha = 0

	if smokeTime > blackoutStart then
		local timeHeldPastThreshold = smokeTime - blackoutStart
		local blackoutDuration = self.LongestTime - blackoutStart
		local blackoutProgress = timeHeldPastThreshold / blackoutDuration

		targetAlpha = blackoutProgress * 255
	end

	self.BlackoutAlpha = math.Approach( self.BlackoutAlpha, targetAlpha, FrameTime() * speed * 2 )

	if self.BlackoutAlpha > 0 then
		surface.SetDrawColor( 0, 0, 0, self.BlackoutAlpha )
		surface.DrawRect( -1, -1, ScrW() + 1, ScrH() + 1 )
	end

	return true
end