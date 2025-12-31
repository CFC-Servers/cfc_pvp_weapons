SWEP.PrintName = "Zaza"
SWEP.Author = "Isemenuk27"
SWEP.DrawWeaponInfoBox = false

SWEP.Slot = 4
SWEP.SlotPos = 8

SWEP.Spawnable = true

SWEP.ViewModel = "models/weapons/c_zaza.mdl"
SWEP.WorldModel = "models/props_prsbox/zaza_small.mdl"
SWEP.ViewModelFOV = 59
SWEP.UseHands = true

SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "none"

SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = "none"

SWEP.DrawAmmo = false
SWEP.AdminOnly = false

SWEP.OnlyOneInInventory = true

SWEP.IronSightsPos = Vector( 8.52, -4.527, 0.55 )
SWEP.IronSightsAng = Angle( -2.724, -4.903, 0 )

SWEP.VignetteMaterial = Material( "fx/cfc_zaza_vignette" )
SWEP.Alpha = 0

local sThisEntClass = "cfc_prsbox_zaza"

if CLIENT then -- killicon, HUD icon and language 'translation'
	CFCPvPWeapons.CL_SetupSwep( SWEP, sThisEntClass, "materials/entities/" .. sThisEntClass .. ".png" )
end

function SWEP:SetupDataTables()
	self:NetworkVar( "Float", 0, "NextIdle" )
	self:NetworkVar( "Float", 1, "Smoke" )
	self:NetworkVar( "Float", 2, "EndEmit" )

	self:NetworkVar( "Bool",  0, "Use" )
end

function SWEP:Initialize()
	self:SetHoldType( "slam" )
end

function SWEP:Reload()
	return false
end

function SWEP:PrimaryAttack()
	if IsFirstTimePredicted() then
		self:SetUse( not self:GetUse() )
	end
end

function SWEP:SecondaryAttack()
	return
end

local function FormatViewModelAttachment( nFOV, vOrigin, bFrom )
	local vEyePos = EyePos()
	local aEyesRot = EyeAngles()
	local vOffset = vOrigin - vEyePos
	local vForward = aEyesRot:Forward()

	local nViewX = math.tan( nFOV * math.pi / 360 )

	if nViewX == 0 then
		vForward:Mul( vForward:Dot( vOffset ) )
		vEyePos:Add( vForward )

		return vEyePos
	end

	-- FIXME: LocalPlayer():GetFOV() should be replaced with EyeFOV() when it's binded
	local nWorldX = math.tan( LocalPlayer():GetFOV() * math.pi / 360 )

	if nWorldX == 0 then
		vForward:Mul( vForward:Dot( vOffset ) )
		vEyePos:Add( vForward )

		return vEyePos
	end

	local vRight = aEyesRot:Right()
	local vUp = aEyesRot:Up()

	if bFrom then
		local nFactor = nWorldX / nViewX
		vRight:Mul( vRight:Dot( vOffset ) * nFactor )
		vUp:Mul( vUp:Dot( vOffset ) * nFactor )
	else
		local nFactor = nViewX / nWorldX
		vRight:Mul( vRight:Dot( vOffset ) * nFactor )
		vUp:Mul( vUp:Dot( vOffset ) * nFactor )
	end

	vForward:Mul( vForward:Dot( vOffset ) )

	vEyePos:Add( vRight )
	vEyePos:Add( vUp )
	vEyePos:Add( vForward )

	return vEyePos
end

local vGrav = Vector( 0, 0, 10 )
local str = "particle/smokesprites_%04i"

function SWEP:GetSmokeTexture()
	return string.format( str, math.random( 1, 16 ) )
end

function SWEP:ViewModelDrawn()
	local CT = CurTime()

	local eOwner = self:GetOwner()

	if self:GetEndEmit() > CT then
		local pos = eOwner:GetShootPos() - vector_up * 3
		local PEmiter = ParticleEmitter( pos )
		local part = PEmiter:Add( self:GetSmokeTexture(), pos )

		if part then
			part:SetDieTime( math.Rand( 3, 6 ) )
			part:SetRoll( math.Rand( -1, 1 ) )

			part:SetStartAlpha( 10 )
			part:SetEndAlpha( 0 )

			part:SetStartSize( 2 )
			part:SetEndSize( 30 )

			part:SetVelocity( eOwner:GetAimVector() * 20 )

			part:SetGravity( vGrav )
		end

		PEmiter:Finish()
	end

	if ( self.NextEmit or 0 ) > CT then return end

	local pViewModel = eOwner:GetViewModel()

	local att = pViewModel:GetAttachment( pViewModel:LookupAttachment( "muzzle" ) )

	if not att then
		return
	end

	local pos1 = att.Ang:Forward()

	pos1:Mul( -6 )

	pos1:Add( att.Pos )

	local pos = FormatViewModelAttachment( self.ViewModelFOV, pos1, false )

	local PEmiter = ParticleEmitter( pos )
	local part = PEmiter:Add( self:GetSmokeTexture(), pos )

	if part then
		part:SetDieTime( math.Rand( 1, 5 ) )
		part:SetRoll( math.Rand( -1, 1 ) )

		part:SetStartAlpha( 10 )
		part:SetEndAlpha( 0 )

		part:SetStartSize( 1 )
		part:SetEndSize( 10 )

		part:SetGravity( vGrav )
	end

	PEmiter:Finish()

	local delay = math.Remap( math.min( 400, eOwner:GetVelocity():Length() ), 0, 400, .1, .01 )

	self.NextEmit = CT + delay
end

function SWEP:PreDrawViewModel()
end

function SWEP:ShouldDropOnDie()
	return true
end

SWEP.LongestTime = 5
SWEP.ExhaleTime = 2
SWEP.HealthPerExhale = 42
SWEP.MaxHealth = 110

sound.Add( {
	name = "ZAZA.EXHALE",
	channel = CHAN_VOICE,
	volume = 1.0,
	level = 70,
	pitch = {95, 110},
	sound = "fx/zaza_exhale.ogg"
} )

local SndExhale = Sound( "ZAZA.EXHALE" )

function SWEP:Exhale( Frac )
	local eOwner = self:GetOwner()
	eOwner:EmitSound( SndExhale )

	self:SetUse( false )

	local cd = CurTime() + self.ExhaleTime * Frac

	self:SetEndEmit( cd )
	self:SetNextPrimaryFire( CurTime() + self.LongestTime + .25 )

	local CurHealth = eOwner:Health()

	if CurHealth < self.MaxHealth then
		local toheal = self.HealthPerExhale * Frac
		local newheath = math.min( self.MaxHealth, CurHealth + toheal )
		eOwner:SetHealth( newheath )
	end

	AddCameraEffector( eOwner, "PRSBOX.ZAZA" )
end

local entMeta = FindMetaTable( "Entity" )
local CurTime = CurTime
local FrameTime = FrameTime

function SWEP:Think()
	local myTbl = entMeta.GetTable( self )
	local owner = entMeta.GetOwner( self )

	local CT = CurTime()
	local idletime = myTbl.GetNextIdle( self )

	if idletime > 0 and CT > idletime then
		local vm = owner:GetViewModel()
		vm:SendViewModelMatchingSequence( vm:LookupSequence( "idle" ) )

		myTbl.UpdateNextIdle( self, CT )
	end

	if CLIENT then
		return
	end

	if myTbl.GetUse( self ) then
		local SmokeTime = myTbl.GetSmoke( self ) + FrameTime()

		if SmokeTime > myTbl.LongestTime then
			SmokeTime = 0
			self:Exhale( 1 )
		end

		myTbl.SetSmoke( self, SmokeTime )
	else
		local SmokeTime = myTbl.GetSmoke( self )

		if SmokeTime > 0 then
			self:Exhale( SmokeTime / self.LongestTime )
		end

		myTbl.SetSmoke( self, 0 )
	end
end

function SWEP:UpdateNextIdle( CT )
	local vm = self:GetOwner():GetViewModel()
	self:SetNextIdle( CT + vm:SequenceDuration() / vm:GetPlaybackRate() )
end

function SWEP:Deploy()
	local vm = self:GetOwner():GetViewModel()
	vm:SendViewModelMatchingSequence( vm:LookupSequence( "draw" ) )

	local CT = CurTime()

	self:SetNextPrimaryFire( CT + vm:SequenceDuration() )
	self:SetNextSecondaryFire( CT + vm:SequenceDuration() )
	self:UpdateNextIdle( CT )

	return true
end

local Mul = 0
local fInt = 0
local EaseFunc = math.ease.InOutSine

function SWEP:GetViewModelPosition( vEyePos, EyeAng )
	local bAimState = self:GetUse()

	local iAimState = bAimState and 1 or 0
	Mul = math.Approach( Mul, iAimState, FrameTime() * 3 )

	fInt = EaseFunc( Mul )

	self.SwayScale = math.Remap( fInt, 0, 1, 1, .2 )
	self.BobScale = math.Remap( fInt, 0, 1, 1, .1 )

	local Pos, Ang = LocalToWorld( self.IronSightsPos * -fInt, self.IronSightsAng * fInt, vEyePos, EyeAng )

	return Pos, Ang
end

SWEP.WMPos = Vector( 2.2, -7, 1 )
SWEP.WMAng = Angle( 180, 0, 0 )
SWEP.AnimMul = 0

local UpperArm = Angle( 60, -70, 0 )
local Forearm = Angle( -8, -30, 0 )
local Hand = Angle( 0, -60, 90 )

function SWEP:DrawWorldModel()
	local eOwner = self:GetOwner()

	if not IsValid( eOwner ) then
		self:DrawModel()
		self:DrawShadow()

		return
	end

	local bAimState = self:GetUse()

	local pos, ang = eOwner:GetBonePosition( eOwner:LookupBone( "ValveBiped.Bip01_R_Hand" ) )

	local iAimState = bAimState and 1 or 0

	self.AnimMul = math.Approach( self.AnimMul, iAimState, FrameTime() * 3 )
	self.InterpAnim = EaseFunc( self.AnimMul )
	local fAim = self.InterpAnim

	if pos and ang then
		ang:RotateAroundAxis( ang:Right() , self.WMAng[1] )
		ang:RotateAroundAxis( ang:Up(), 	self.WMAng[2] + fAim * -60 )
		ang:RotateAroundAxis( ang:Forward(),self.WMAng[3] )

		pos = pos + ( self.WMPos[1] + fAim * 4 ) * ang:Right()
		pos = pos + ( self.WMPos[2] + fAim * 4 ) * ang:Forward()
		pos = pos + self.WMPos[3] * ang:Up()

		self:SetRenderOrigin( pos )
		self:SetRenderAngles( ang )
		self:DrawModel()
		self:DrawShadow()
	else
		self:SetRenderOrigin( self:GetPos() )
		self:SetRenderAngles( self:GetAngles() )
		self:DrawModel()
		self:DrawShadow()
	end

	local CT = CurTime()

	if ( self.NextEmit or 0 ) < CT then
		local posEmit = self:GetPos()

		local PEmiter = ParticleEmitter( posEmit )
		local part = PEmiter:Add( self:GetSmokeTexture(), posEmit )

		if part then
			part:SetDieTime( math.Rand( 1, 5 ) )
			part:SetRoll( math.Rand( -1, 1 ) )

			part:SetStartAlpha( 10 )
			part:SetEndAlpha( 0 )

			part:SetStartSize( 1 )
			part:SetEndSize( 10 )

			part:SetGravity( vGrav )
		end

		PEmiter:Finish()

		local delay = math.Remap( math.min( 400, eOwner:GetVelocity():Length() ), 0, 400, .1, .01 )

		self.NextEmit = CT + delay
	end

	if self:GetEndEmit() > CT then
		local obj = eOwner:LookupAttachment( "mouth" )

		local muzzle = eOwner:GetAttachment( obj )

		local posEmit

		if muzzle then
			posEmit = muzzle.Pos
		else
			posEmit = eOwner:GetShootPos() - eOwner:EyeAngles():Up() * 4.34
		end

		local PEmiter = ParticleEmitter( posEmit )
		local part = PEmiter:Add( self:GetSmokeTexture(), posEmit )

		if part then
			part:SetDieTime( math.Rand( 3, 6 ) )
			part:SetRoll( math.Rand( -1, 1 ) )

			part:SetStartAlpha( 10 )
			part:SetEndAlpha( 0 )

			part:SetStartSize( 2 )
			part:SetEndSize( 30 )

			part:SetVelocity( eOwner:GetAimVector() * 20 )

			part:SetGravity( vGrav )
		end

		PEmiter:Finish()
	end

	eOwner:ManipulateBoneAngles( eOwner:LookupBone( "ValveBiped.Bip01_R_UpperArm" ), UpperArm * fAim )
	eOwner:ManipulateBoneAngles( eOwner:LookupBone( "ValveBiped.Bip01_R_Forearm" ), Forearm * fAim )
	eOwner:ManipulateBoneAngles( eOwner:LookupBone( "ValveBiped.Bip01_R_Hand" ), Hand * fAim )
end

function SWEP:DrawHUD()
	if not self.VignetteMaterial then return end
	if self.VignetteMaterial:IsError() then return end -- the content always finds some way to not load
	surface.SetMaterial( self.VignetteMaterial )
	self.Alpha = math.Approach( self.Alpha, self:GetUse() and 255 or 0, FrameTime() * 75 )

	surface.SetDrawColor( 255, 255, 255, self.Alpha )

	for _ = 1, 3 do
		surface.DrawTexturedRect( 0, 0, ScrW(), ScrH() )
	end
end

function SWEP:Holster()
	self:SetUse( false )

	self.Alpha = 0

	if self:GetSmoke() > 0 then return false end

	local eOwner = self:GetOwner()

	if IsValid( eOwner ) then
		eOwner:ManipulateBoneAngles( eOwner:LookupBone( "ValveBiped.Bip01_R_UpperArm" ), angle_zero )
		eOwner:ManipulateBoneAngles( eOwner:LookupBone( "ValveBiped.Bip01_R_Forearm" ), angle_zero )
		eOwner:ManipulateBoneAngles( eOwner:LookupBone( "ValveBiped.Bip01_R_Hand" ), angle_zero )
	end

	return true
end

if CLIENT then
	local zaza = {
		functionX = function( _ ) return 0 end,
		functionY = function( _ ) return TimedSin( 1, 0, 1, 0 ) end,
		functionZ = function( _ ) return TimedCos( .6, 0, 2, 0 ) end,
		FadeIn		= 1,
		FadeOut		= 6,
		LifeTime	= 15,
	}

	RegisterCameraEffector( "PRSBOX.ZAZA", zaza )
elseif SERVER then
	SWEP.IsZaza = true

	hook.Add( "PlayerCanPickupWeapon", "ZAZA.NOEXTRAPICKUP", function( ply, weapon )
		if not weapon.IsZaza then return end
		if weapon:IsValid() and ply:HasWeapon( sThisEntClass ) then
			return false
		end
	end )
end
