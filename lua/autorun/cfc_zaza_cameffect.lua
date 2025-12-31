--	https://github.com/Prostir-Team/gmod-prsbox/blob/main/lua/autorun/CameraEffector.lua
--
--

if ( AddCameraEffector ~= nil ) then
	return
end

if ( CLIENT ) then
	local camView = { angles = Angle( 0, 0, 0 ) }
	aAnimAngles = Angle( 0, 0, 0 )
	local next, setmetatable = next, setmetatable
	local Remap, floor = math.Remap, math.floor
	local DeltaTime, pairs, CurTime = FrameTime, pairs, CurTime
	local sin, cos = math.sin, math.cos
	local rad, deg = math.rad, math.deg
	local OutSine, InOutSine = math.ease.OutSine, math.ease.InOutSine
	local InBack = math.ease.InBack
	local PI, PI2, PIDiv2, sqrt = math.pi, math.pi * 2, math.pi * .5, math.sqrt

	CamEffector = CamEffector or {}
	CamEffector.Effectors = CamEffector.Effectors or {}
	CamEffector.ActiveEffectors = CamEffector.ActiveEffectors or 0

	CamEffector.Registered = {}

	function RegisterCameraEffector( index, infotable )

		if ( infotable.fps ) then
			infotable.Animated = true
		end

		if ( not CamEffector.Registered[ index ] ) then
			CamEffector.RegisteredCount = ( CamEffector.RegisteredCount or 0 ) + 1
		else
			print( "CamEffector with", index, "index already registered!!!" )
		end

		CamEffector.Registered[ index ] = infotable

		return true
	end

	local CCamEffector = {}

	local CalcView
	local HookName, HookIndex = "CalcView", "CCamEffector"

	local DefaultAnim = {
		{ 1.570553, 0.0, -0.001344 },
		{ 1.940924, 0.147129, 0.050565 },
		{ 2.328190, 0.232661, 0.202905 },
		{ 2.493722, 0.231784, 0.277014 },
		{ 2.453459, 0.193956, 0.206346 },
		{ 2.392136, 0.110752, 0.087877 },
		{ 2.325298, 0.001632, -0.035228 },
		{ 2.256868, -0.104652, -0.128344 },
		{ 2.179110, -0.169682, -0.166035 },
		{ 2.085210, -0.162200, -0.145471 },
		{ 1.982650, -0.095321, -0.100896 },
		{ 1.880009, 0.002461, -0.062714 },
		{ 1.779050, 0.094652, -0.046822 },
		{ 1.678293, 0.140567, -0.053960 },
		{ 1.579735, 0.133249, -0.069027 },
		{ 1.487243, 0.099654, -0.078381 },
		{ 1.403299, 0.050261, -0.077261 },
		{ 1.329493, -0.004337, -0.065622 },
		{ 1.267418, -0.054357, -0.046882 },
		{ 1.219421, -0.091223, -0.027051 },
		{ 1.188650, -0.107339, -0.013367 },
		{ 1.171610, -0.105635, -0.007404 },
		{ 1.162189, -0.095340, -0.005680 },
		{ 1.159645, -0.078515, -0.007351 },
		{ 1.163195, -0.057074, -0.011286 },
		{ 1.172099, -0.032865, -0.016233 },
		{ 1.185699, -0.007749, -0.020959 },
		{ 1.203442, 0.016348, -0.024351 },
		{ 1.224861, 0.037399, -0.025506 },
		{ 1.249537, 0.053255, -0.023795 },
		{ 1.277046, 0.061646, -0.018926 },
		{ 1.306825, 0.064589, -0.012174 },
		{ 1.338241, 0.065721, -0.005023 },
		{ 1.370722, 0.065172, 0.002210 },
		{ 1.403693, 0.063088, 0.009220 },
		{ 1.436581, 0.059634, 0.015725 },
		{ 1.468814, 0.054995, 0.021471 },
		{ 1.499826, 0.049368, 0.026245 },
		{ 1.529053, 0.042964, 0.029877 },
		{ 1.555936, 0.035999, 0.032290 },
		{ 1.579919, 0.028690, 0.033632 },
		{ 1.600447, 0.021251, 0.034077 },
		{ 1.616964, 0.013890, 0.033791 },
		{ 1.628916, 0.006806, 0.032938 },
		{ 1.636370, 0.000194, 0.031686 },
		{ 1.640624, -0.005757, 0.030177 },
		{ 1.642547, -0.010857, 0.028509 },
		{ 1.642672, -0.014914, 0.026751 },
		{ 1.641354, -0.017735, 0.024951 },
		{ 1.638844, -0.019158, 0.023137 },
		{ 1.635326, -0.019529, 0.021291 },
		{ 1.630945, -0.019189, 0.019390 },
		{ 1.625812, -0.018322, 0.017420 },
		{ 1.620023, -0.017041, 0.015371 },
		{ 1.613654, -0.015417, 0.013237 },
		{ 1.606777, -0.013499, 0.011011 },
		{ 1.599462, -0.011320, 0.008689 },
		{ 1.591791, -0.008900, 0.006266 },
		{ 1.583876, -0.006244, 0.003743 },
		{ 1.575982, -0.003333, 0.001133 },
		{ 1.570553, 0.000085, -0.001344 },
		fps = 30,
		length = 60,
		fadein = .05,
		fadeout = 1.5,
	}

	function CCamEffector:New( tMotion, fSpeed )
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

		if ( CT >= self.fDuration ) then 
			self:Kill() 
			return 0, 0, 0, 0 
		end

		local fFrameIndex = round(self.fCurFrame)
		
		local tMotion = self.tMotion[ fFrameIndex ]
		if ( not tMotion ) then tMotion = self.tMotion[ self.fMotionLen ] end

		local fX, fY, fZ = tMotion[1], tMotion[2], tMotion[3]

		if ( fFrameIndex != self.fPrevFrameIndex ) then
			self.fFrameCurTime = 0
			self.fFrameInterpLinear = 0
			local tPrevMotion = self.tMotion[ fFrameIndex - 1 ]
			if ( tPrevMotion ) then
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

		if ( self.fFadeIn and CT <= self.fFadeIn ) then
			fAmp = InOutSine( Remap( CT, 0, self.fFadeIn, 0, 1 ) )
		elseif ( CT >= self.fFadeOut ) then
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
		functionX = function( x ) return TimedSin(1, 0, 1 * 3, 0) end,
		functionY = function( x ) return TimedSin(1.2, 0, 2 * 3, 0) end,
		functionZ = function( x ) return 0 end,
		--FadeIn		= 1,
		FadeOut		= 2,
		LifeTime	= 5,
	}

	function CCamEffectorFunc:New( tInfo )
		self.fCurTime = 0
		self.fDieTime = tInfo.LifeTime or 6		
		self.fFadeInTime = tInfo.FadeIn or nil
		self.fFadeOutTime = self.fDieTime - (tInfo.FadeOut or 2)

		self.fXfunc = tInfo.functionX
		self.fYfunc = tInfo.functionY
		self.fZfunc = tInfo.functionZ
	end

	function CCamEffectorFunc:Think( fFrameTime )
		local CT = self.fCurTime

		if ( CT >= self.fDieTime ) then self:Kill() return 0, 0, 0, 0 end

		local fAmp
		if ( self.fFadeInTime and CT <= self.fFadeInTime ) then
			fAmp = Remap( CT, 0, self.fFadeInTime, 0, 1 )
		elseif ( CT >= self.fFadeOutTime ) then
			fAmp = InBack( Remap( CT, self.fFadeOutTime, self.fDieTime, 1, 0 ) )
		else
			fAmp = 1
		end

		self.fCurTime = CT + fFrameTime

		return self.fXfunc( CT ) * fAmp, self.fYfunc( CT ) * fAmp, self.fZfunc( CT ) * fAmp
	end

	CCamEffectorFunc.__index = CCamEffectorFunc

	local Player = FindMetaTable("Player")
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
			hook.Add( HookName, HookIndex, CalcView)
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
		if ( CamEffector.ActiveEffectors == 0 ) then
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

	concommand.Add("cam_effector_test_func", function()
		CamEffector:AddFunction()
	end)

	concommand.Add("cam_effector_test_anim", function()
		CamEffector:AddAnimated()
	end)

	local fLastKillAll = 0

	concommand.Add("cam_effector_killall", function()
		local CT = CurTime()
		if ( fLastKillAll > CT ) then print("Fuck you!") return end
		fLastKillAll = CT + 120
		for k,eff in pairs(CamEffector.Effectors) do
			eff:Kill()
		end
	end)

	local fNextHeadShotTime = 0

	CalcView = function ( ply, pos, ang, fov )
		if ( GetViewEntity() != LocalPlayer() ) then return end
		local weapon = ply:GetActiveWeapon()
		if ( IsValid( weapon ) and weapon.CW20Weapon ) then
			weapon.CurFOVMod = 0
			weapon.FOVTarget = 0
			weapon.BreathFOVModifier = 0
		end
		local fDeltaTime = DeltaTime()
		camView.angles:Zero()

		for k, eff in pairs(CamEffector.Effectors) do
			local x, y, z = eff:Think( fDeltaTime )

			camView.angles.x = camView.angles.x - x
			camView.angles.y = camView.angles.y - y
			camView.angles.z = camView.angles.z - z
		end
		aAnimAngles:Set(camView.angles)
		camView.angles:Add( ang )
		return camView
	end

	local function TakeDamage()
		local CT = CurTime()
		if ( fNextHeadShotTime <= CT ) then
			CamEffector:AddAnimated()
			fNextHeadShotTime = CT + 1
			return
		end
	end

	net.Receive( "CamEffector.Damage", TakeDamage )

	function AddCameraEffector( ply, index )
		local cEffector = CamEffector.Registered[ index ]

		if ( cEffector.Animated ) then
			CamEffector:AddAnimated( cEffector )
		else
			CamEffector:AddFunction( cEffector )
		end
	end

	net.Receive( "CamEffector.Data", function()
		AddCameraEffector( LocalPlayer(), net.ReadString() )
	end )
else
	util.AddNetworkString("CamEffector.Damage")
	util.AddNetworkString("CamEffector.Data")

	function AddCameraEffector( ply, index )
		net.Start("CamEffector.Data")
			net.WriteString( index )
		net.Send( ply )
	end
end
