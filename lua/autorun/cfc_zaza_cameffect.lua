--	https://github.com/Prostir-Team/gmod-prsbox/blob/main/lua/autorun/CameraEffector.lua
--
--

if AddCameraEffector ~= nil then
	return
end

if CLIENT then
	local camView = { angles = Angle( 0, 0, 0 ) }
	aAnimAngles = Angle( 0, 0, 0 )

	local setmetatable = setmetatable
	local Remap, floor = math.Remap, math.floor
	local DeltaTime, pairs, CurTime = FrameTime, pairs, CurTime
	local InOutSine = math.ease.InOutSine
	local InBack = math.ease.InBack
	local PI2 = math.pi * 2

	CamEffector = CamEffector or {}
	CamEffector.Effectors = CamEffector.Effectors or {}
	CamEffector.ActiveEffectors = CamEffector.ActiveEffectors or 0

	CamEffector.Registered = {}

	function RegisterCameraEffector( index, infotable )

		if infotable.fps then
			infotable.Animated = true
		end

		if not CamEffector.Registered[ index ] then
			CamEffector.RegisteredCount = ( CamEffector.RegisteredCount or 0 ) + 1
		else
			print( "CamEffector with", index, "index already registered!!! Overriding!" )
		end

		CamEffector.Registered[ index ] = infotable

		return true
	end

	local CCamEffector = {}

	local CalcView
	local HookName, HookIndex = "CalcView", "CCamEffector"

	local DefaultAnim = {
		fps = 30,
		length = 60,
		fadein = .05,
		fadeout = 1.5,
	}

	function CCamEffector:New( tMotion, _fSpeed )
		self.tMotion = tMotion or DefaultAnim
		self.fCurTime = 0

		self.fFPS = self.tMotion.fps
		self.fMotionLen = self.tMotion.length + 1
		self.fDuration = self.fMotionLen / self.fFPS

		self.fFadeIn = self.tMotion.fadein or nil
		self.fFadeOut = self.tMotion.fadeout and self.fDuration - self.tMotion.fadeout or nil

		self.fCurFrame = 1
		self.fFrameInterpLinear = 0
		self.fFrameCurTime = 0
		self.fFrameTime = self.fDuration / self.fMotionLen
		self.fBaseAmp = 45 / PI2
		self.fPrevFrameIndex = 0

		self.fPrevX = self.tMotion[1][1]
		self.fPrevY = self.tMotion[1][2]
		self.fPrevZ = self.tMotion[1][3]
		return self
	end

	function CCamEffector:Kill()
		CamEffector:Recalc( self.iID )
		self = nil
		return
	end

	local function round( val )
		return floor( val + .5 )
	end

	function CCamEffector:Think( fFrameTime )
		local CT = self.fCurTime

		if CT >= self.fDuration then
			self:Kill()
			return 0, 0, 0, 0
		end

		local fFrameIndex = round( self.fCurFrame )

		local tMotion = self.tMotion[ fFrameIndex ]
		if not tMotion then tMotion = self.tMotion[ self.fMotionLen ] end

		local fX, fY, fZ = tMotion[1], tMotion[2], tMotion[3]

		if fFrameIndex ~= self.fPrevFrameIndex then
			self.fFrameCurTime = 0
			self.fFrameInterpLinear = 0
			local tPrevMotion = self.tMotion[ fFrameIndex - 1 ]
			if tPrevMotion then
				self.fPrevX = tPrevMotion[1]
				self.fPrevY = tPrevMotion[2]
				self.fPrevZ = tPrevMotion[3]
			end
		end

		self.fFrameInterpLinear = Remap( self.fFrameCurTime, 0, self.fFrameTime, 0, 1 )

		fX = self.fPrevX + ( fX - self.fPrevX ) * self.fFrameInterpLinear --fEasedInterp
		fY = self.fPrevY + ( fY - self.fPrevY ) * self.fFrameInterpLinear --fEasedInterp
		fZ = self.fPrevZ + ( fZ - self.fPrevZ ) * self.fFrameInterpLinear --fEasedInterp

		local fAmp

		if self.fFadeIn and CT <= self.fFadeIn then
			fAmp = InOutSine( Remap( CT, 0, self.fFadeIn, 0, 1 ) )
		elseif CT >= self.fFadeOut then
			fAmp = InBack( Remap( CT, self.fFadeOut, self.fDuration, 1, 0 ) )
		else
			fAmp = 1
		end

		self.fFrameCurTime = self.fFrameCurTime + fFrameTime
		self.fCurTime = CT + fFrameTime
		self.fCurFrame = Remap( CT, 0, self.fDuration, 1, self.fMotionLen )

		self.fPrevFrameIndex = fFrameIndex

		return fX * fAmp * self.fBaseAmp, fY * fAmp * self.fBaseAmp, fZ * fAmp * self.fBaseAmp
	end

	CCamEffector.__index = CCamEffector

	local CCamEffectorFunc = {}
	setmetatable( CCamEffectorFunc, CCamEffector )

	local DefaultInfo = {
		functionX = function( _x ) return TimedSin( 1, 0, 1 * 3, 0 ) end,
		functionY = function( _x ) return TimedSin( 1.2, 0, 2 * 3, 0 ) end,
		functionZ = function( _x ) return 0 end,
		--FadeIn		= 1,
		FadeOut		= 2,
		LifeTime	= 5,
	}

	function CCamEffectorFunc:New( tInfo )
		self.fCurTime = 0
		self.fDieTime = tInfo.LifeTime or 6
		self.fFadeInTime = tInfo.FadeIn or nil
		self.fFadeOutTime = self.fDieTime - ( tInfo.FadeOut or 2 )

		self.fXfunc = tInfo.functionX
		self.fYfunc = tInfo.functionY
		self.fZfunc = tInfo.functionZ
	end

	function CCamEffectorFunc:Think( fFrameTime )
		local CT = self.fCurTime

		if CT >= self.fDieTime then self:Kill() return 0, 0, 0, 0 end

		local fAmp
		if self.fFadeInTime and CT <= self.fFadeInTime then
			fAmp = Remap( CT, 0, self.fFadeInTime, 0, 1 )
		elseif CT >= self.fFadeOutTime then
			fAmp = InBack( Remap( CT, self.fFadeOutTime, self.fDieTime, 1, 0 ) )
		else
			fAmp = 1
		end

		self.fCurTime = CT + fFrameTime

		return self.fXfunc( CT ) * fAmp, self.fYfunc( CT ) * fAmp, self.fZfunc( CT ) * fAmp
	end

	CCamEffectorFunc.__index = CCamEffectorFunc

	local Player = FindMetaTable( "Player" )
	local GetViewPunchAngles = Player.GetViewPunchAngles

	local function PunchAngle( ply )
		return GetViewPunchAngles( ply ) + aAnimAngles
	end

	function CamEffector:Add( Effector )
		local i = #self.Effectors + 1

		self.Effectors[i] = {}
		setmetatable( self.Effectors[i], Effector )
		self.Effectors[i].iID = i

		if self.ActiveEffectors == 0 then
			hook.Add( HookName, HookIndex, CalcView )
			Player.GetPunchAngle = PunchAngle
		end

		self.ActiveEffectors = self.ActiveEffectors + 1

		return self.Effectors[i]
	end

	function CamEffector:AddAnimated( tMotion )
		local Effector = self:Add( CCamEffector )
		Effector:New( tMotion )
		return Effector
	end

	function CamEffector:Recalc( iID )
		CamEffector.Effectors[iID] = nil
		CamEffector.ActiveEffectors = CamEffector.ActiveEffectors - 1
		if CamEffector.ActiveEffectors == 0 then
			hook.Remove( HookName, HookIndex )
			camView.angles:Zero()
			aAnimAngles:Zero()
			Player.GetPunchAngle = GetViewPunchAngles
		end
	end

	function CamEffector:AddFunction( fFunc )
		local Effector = self:Add( CCamEffectorFunc )
		Effector:New( fFunc or DefaultInfo )
		return Effector
	end

	concommand.Add( "cam_effector_test_func", function()
		CamEffector:AddFunction()
	end )

	concommand.Add( "cam_effector_test_anim", function()
		CamEffector:AddAnimated()
	end )

	local fLastKillAll = 0

	concommand.Add( "cam_effector_killall", function()
		local CT = CurTime()
		if fLastKillAll > CT then print( "Fuck you!" ) return end
		fLastKillAll = CT + 120
		for _, eff in pairs( CamEffector.Effectors ) do
			eff:Kill()
		end
	end )

	local fNextHeadShotTime = 0

	CalcView = function ( ply, _pos, ang, _fov )
		if GetViewEntity() ~= LocalPlayer() then return end
		local weapon = ply:GetActiveWeapon()
		if IsValid( weapon ) and weapon.CW20Weapon then
			weapon.CurFOVMod = 0
			weapon.FOVTarget = 0
			weapon.BreathFOVModifier = 0
		end
		local fDeltaTime = DeltaTime()
		camView.angles:Zero()

		for _, eff in pairs( CamEffector.Effectors ) do
			local x, y, z = eff:Think( fDeltaTime )

			camView.angles.x = camView.angles.x - x
			camView.angles.y = camView.angles.y - y
			camView.angles.z = camView.angles.z - z
		end
		aAnimAngles:Set( camView.angles )
		camView.angles:Add( ang )
		return camView
	end

	local function TakeDamage()
		local CT = CurTime()
		if fNextHeadShotTime <= CT then
			CamEffector:AddAnimated()
			fNextHeadShotTime = CT + 1
			return
		end
	end

	net.Receive( "CamEffector.Damage", TakeDamage )

	function AddCameraEffector( _ply, index )
		local cEffector = CamEffector.Registered[ index ]

		if cEffector.Animated then
			CamEffector:AddAnimated( cEffector )
		else
			CamEffector:AddFunction( cEffector )
		end
	end

	net.Receive( "CamEffector.Data", function()
		AddCameraEffector( LocalPlayer(), net.ReadString() )
	end )
else
	util.AddNetworkString( "CamEffector.Damage" )
	util.AddNetworkString( "CamEffector.Data" )

	function AddCameraEffector( ply, index )
		net.Start( "CamEffector.Data" )
			net.WriteString( index )
		net.Send( ply )
	end
end
