AddCSLuaFile()

DEFINE_BASECLASS( "cfc_simple_base" )
SWEP.Base = "cfc_simple_base"

SWEP.CFCSimpleWeapon = true
SWEP.CFCSimpleWeaponCharge = true

-- UI stuff

SWEP.PrintName = "cfc_charge_gun_base"
SWEP.Category = "CFC"

SWEP.Slot = 0
SWEP.Spawnable = false

-- Appearance

SWEP.UseHands = true -- If your viewmodel includes it's own hands (v_ model instead of a c_ model), set this to false

SWEP.ViewModelTargetFOV = 65
SWEP.ViewModel = Model( "models/weapons/c_rpg.mdl" ) -- Weapon viewmodel, usually a c_ or v_ model
SWEP.WorldModel = Model( "models/weapons/w_rocket_launcher.mdl" ) -- Weapon worldmodel, almost always a w_ model

SWEP.HoldType = "rpg" -- https://wiki.facepunch.com/gmod/Hold_Types
SWEP.CustomHoldType = {} -- Allows you to override any hold type animations with your own, uses [ACT_MP_STAND_IDLE] = ACT_HL2MP_IDLE_SHOTGUN formatting

-- Weapon stats

SWEP.Firemode = 0

SWEP.Primary = {
    Ammo = "Buckshot", -- The ammo type used when reloading
    Cost = 1, -- A remnant of cfc_simple_base. Leave as 1.

    ClipSize = 15, -- The max ammount of ammo for a full charge
    DefaultClip = 1000, -- How many rounds the player gets when picking up the weapon for the first time, excess ammo will be added to the player's reserves

    Damage = 1, -- Damage per shot
    Count = 1, -- Optional: Shots fired per unit ammo

    PumpAction = false, -- Optional: Tries to pump the weapon between shots
    PumpSound = "Weapon_Shotgun.Special1", -- Optional: Sound to play when pumping

    Delay = 0.15, -- Delay between each buildup of charge, use 60 / x for RPM (Rounds per minute) values
    BurstEnabled = true, -- When releasing the charge, decides whether to burst-fire the weapon once per unit ammo, or to expend the full charge in one fire call
    BurstDelay = 0.075, -- Burst only: the delay between shots during a burst
    Cooldown = 3, -- Cooldown to apply once the charge is expended
    MovementMultWhenCharging = 1, -- Multiplier against movement speed when charging
    OverchargeDelay = false, -- Once at full charge, it takes this long before overcharge occurs. False to disable overcharge.

    Range = 750, -- The range at which the weapon can hit a plate with a diameter of <Accuracy> units
    Accuracy = 12, -- The reference value to use for the previous option, 12 = headshots, 24 = bodyshots

    RangeModifier = 0.85, -- The damage multiplier applied for every 1000 units a bullet travels, e.g. 0.85 for 2000 units = 0.85 * 0.85 = 72% of original damage

    Recoil = {
        MinAng = Angle( 1, -0.3, 0 ), -- The minimum amount of recoil punch per shot
        MaxAng = Angle( 1.2, 0.3, 0 ), -- The maximum amount of recoil punch per shot
        Punch = 0.2, -- The percentage of recoil added to the player's view angles, if set to 0 a player's view will always reset to the exact point they were aiming at
        Ratio = 0.4 -- The percentage of recoil that's translated into the viewmodel, higher values cause bullets to end up above the crosshair
    },
    RecoilCharging = {
        Mult = 0, -- If above zero, will repeatedly apply recoil while charging, with this as a strength multiplier. Scales with charge level.
        MinAng = Angle( -2, -1, 0 ),
        MaxAng = Angle( 2, 1, 0 ),
        Punch = 0.2,
        Ratio = 0.4,
    },
    RecoilChargingInterval = 0.1, -- The interval at which to apply the charging recoil

    Reload = { -- Remnant of simple_base, leave as-is
        Time = 0,
        Amount = 1,
        Shotgun = false,
        Sound = ""
    },

    Sound = "doors/vent_open3.wav", -- Firing sound
    TracerName = "", -- Tracer effect, leave blank for no tracer

    ChargeSound = "npc/combine_gunship/engine_rotor_loop1.wav", -- Should be a looping sound
    ChargeVolume = 1,
    ChargeStepSound = "",
    ChargeStepVolume = 1,
    ChargeStepPitchMinStart = 100,
    ChargeStepPitchMaxStart = 100,
    ChargeStepPitchMinEnd = 255,
    ChargeStepPitchMaxEnd = 255,
    ChargeStepPitchEase = function( x ) return x end, -- Use an easing function (e.g. math.ease.InCubic). Default is linear, which isn't in the ease library.

    ChargeSprite = {
        Enabled = false,
        Mat = "sprites/light_glow01", -- Material path for the sprite (should have ignorez)
        MatVM = "cfc_pvp_weapons/sprites/charge_glow", -- Material path for the viewmodel (shouldn't have ignorez)
        Offset = Vector( 25, 0, 0 ), -- Position offset for the sprite
        OffsetVM = Vector( 25, -3, -3 ), -- Position offset for the viewmodel sprite
        Color = Color( 255, 255, 255 ),
        AlphaStart = 0,
        AlphaEnd = 255,
        Framerate = 10,
        ScaleStart = 0, -- Used by the world sprite
        ScaleEnd = 0.75, -- Used by the world sprite
        SizeStart = 0, -- Used by the viewmodel sprite
        SizeEnd = 20, -- Used by the viewmodel sprite
    }
}

SWEP.ViewOffset = Vector( 0, 0, 0 ) -- Optional: Applies an offset to the viewmodel's position


local ANGLE_ZERO = Angle( 0, 0, 0 )

local setMovementMult
local tryApplyChargedMovementMult
local createSpriteEnt


----- OVERRIDABLE FUNCTIONS -----

function SWEP:FireWeapon( _chargeAmount )
    -- Called when the weapon is fired.
    -- chargeAmount is the number of shots to fire, equal to the current charge level.
end

function SWEP:OnChargeStep( _chargeAmount )
    -- Called for each step of the charge sequence.
    -- chargeAmount is the current charge level, starting at 1.
end

function SWEP:OnFullChargeReached( _chargeAmount )
    -- Called when the weapon reaches full charge.
    -- chargeAmount should be equivalent to self.Primary.ClipSize.
end

function SWEP:OnOvercharged()
    -- Called when the weapon is overcharged.
    -- By default, releases the charge early, firing the weapon.

    self:PrimaryRelease()
end

function SWEP:OnStartCharging()
    -- Called when the weapon starts charging.
end

function SWEP:OnStopCharging()
    -- Called when the weapon stops charging.
end

function SWEP:ChargeThink()
    -- Called every tick/frame while the weapon is charging.
end


----- INSTANCE FUNCTIONS -----

function SWEP:Initialize()
    BaseClass.Initialize( self )

    self:SetCharge( 0 )
    self:SetNextFire( 0 )
end

function SWEP:SetupDataTables()
    BaseClass.SetupDataTables( self )

    self:AddNetworkVar( "Float", "ChargeNextTime" )
    self:AddNetworkVar( "Int", "ChargeState" )
    self:AddNetworkVar( "Bool", "Releasing" )
    self:AddNetworkVar( "Entity", "ChargeSprite" )

    if SERVER then
        self:SetChargeNextTime( -1 )
        self:SetChargeState( 0 )
    end

    self.IsReleasing = self.GetReleasing
end

function SWEP:IsCharging()
    return self:GetChargeState() > 0
end

function SWEP:IsOvercharging()
    return self:GetChargeState() == 2
end

function SWEP:Think()
    BaseClass.Think( self )

    self:CheckForPrematureCharge()

    if self:IsCharging() then
        self:ChargeThinkInternal()
        self:ChargeThink()
        self:DoChargeRecoil()
    elseif self:IsReleasing() then
        self:ReleaseThinkInternal()
    end
end

function SWEP:CanPrimaryAttack()
    if self:GetNextFire() > CurTime() then return false end
    if self:GetReserveAmmo() <= 0 then return false end
    --if not self:CanPrimaryFire() then return false end

    return true
end

function SWEP:PrimaryAttack()
    if not self:CanPrimaryAttack() then return end

    local clipMax = self.Primary.ClipSize
    local chargeStep = self.Primary.Delay

    tryApplyChargedMovementMult( self, false )

    if SERVER then
        local chargeSprite = self:_CreateChargeSprite()

        if IsValid( chargeSprite ) then
            self:UpdateChargeSprite()
            chargeSprite:SetNoDraw( false )
        end
    end

    self:SetChargeNextTime( CurTime() + chargeStep )
    self:SetChargeState( 1 )
    self:OnStartCharging()

    if CLIENT then return end

    local rf = RecipientFilter()
    rf:AddAllPlayers()

    local chargeSound = CreateSound( self, self.Primary.ChargeSound, rf )
    self._chargeSound = chargeSound
    chargeSound:Play()
    chargeSound:ChangePitch( 100 )
    chargeSound:ChangePitch( 255, clipMax * chargeStep )
    chargeSound:ChangeVolume( self.Primary.ChargeVolume )
end

function SWEP:Reload()
    -- Do nothing.
end

function SWEP:ForceStopFire()
    -- Do nothing.
end

function SWEP:PrimaryRelease()
    if not self:IsCharging() then return end

    local clip = self:Clip1()
    if clip <= 0 then return end

    self:StopCharge()
    self:SetReleasing( true )

    local cooldown = self.Primary.Cooldown

    -- No burst
    if not self.Primary.BurstEnabled then
        self:SetClip1( 0 )
        self:FireWeapon( clip )
        self:SetNextFire( CurTime() + cooldown )
        self:SetReleasing( false )

        return
    end

    -- Burst
    local burstDelay = self.Primary.BurstDelay
    local now = CurTime()

    self:SetNextFire( now + burstDelay * ( clip - 1 ) + cooldown )
    self:SetChargeNextTime( now )
end

function SWEP:Deploy()
    BaseClass.Deploy( self )
    self:SetCharge( 1 )

    return true
end

function SWEP:Holster()
    if self:IsReleasing() then return false end

    BaseClass.Holster( self )
    self:SetCharge( 0 )
    self:StopCharge()

    return true
end

function SWEP:OnRemove()
    self:SetCharge( 0 )
    self:StopCharge()
    self:_RemoveChargeSprite()
end

function SWEP:OwnerChanged()
    BaseClass.OwnerChanged( self )
    self:SetCharge( 0 )
    self:StopCharge()
    self:SetReleasing( false )
    self:_RemoveChargeSprite()
end

function SWEP:CheckForPrematureCharge()
    if self:IsCharging() then return end
    if self:IsReleasing() then return end

    local owner = self:GetOwner()
    if not IsValid( owner ) then return end

    -- Insert starting charge to indicate that the weapon is ready to charge.
    if self:Clip1() == 0 and self:CanPrimaryAttack() then
        self:SetCharge( 1 )
    end

    if owner:KeyDown( IN_ATTACK ) then
        if not self._prematureChargeOneTickCheck then -- gmod jank
            self._prematureChargeOneTickCheck = true

            return
        end

        self:UpdateChargeSprite() -- Prevent net delay issues making the sprite appear large for one tick. Strangely, only happens from premature charges, not standard ones.
        self:PrimaryAttack()
    else
        self._prematureChargeOneTickCheck = false
    end
end

function SWEP:SetCharge( desClip )
    local clip = self:Clip1()
    if clip == desClip then return end

    local owner = self:GetOwner()

    self:SetClip1( desClip )
    self:UpdateChargeSprite()

    if IsValid( owner ) then
        local ammoType = self.Primary.Ammo
        local curAmmo = owner:GetAmmoCount( ammoType )

        owner:SetAmmo( math.max( curAmmo + clip - desClip, 0 ), ammoType )
    end
end

function SWEP:StopCharge()
    local wasCharging = self:IsCharging()

    self:SetChargeNextTime( -1 )
    self:SetChargeState( 0 )

    local chargeSound = self._chargeSound

    if chargeSound then
        chargeSound:Stop()
        self._chargeSound = nil
    end

    local chargeSprite = self:GetChargeSprite()

    if IsValid( chargeSprite ) then
        chargeSprite:SetNoDraw( true )
    end

    if wasCharging then
        tryApplyChargedMovementMult( self, true )
        self:OnStopCharging()
    end
end

function SWEP:ChargeThinkInternal()
    local now = CurTime()
    local stepTime = self:GetChargeNextTime()
    if stepTime == -1 then return end
    if now < stepTime then return end

    -- Overcharge check
    if self:IsOvercharging() then
        self:OnOvercharged()
        self:StopCharge()

        if not self:IsReleasing() then
            self:SetCharge( 0 )
        end

        return
    end

    -- Charge step
    local ammo = self:GetReserveAmmo()
    if ammo <= 0 then return end

    local clip = self:Clip1() + 1
    local primary = self.Primary
    local clipMax = primary.ClipSize

    self:SetClip1( clip )
    self:SetReserveAmmo( ammo - 1 )
    self:UpdateChargeSprite()

    -- Charge step delay and overcharge check
    if clip >= clipMax then
        local overchargeDelay = self.Primary.OverchargeDelay

        if overchargeDelay then
            self:SetChargeNextTime( stepTime + overchargeDelay )
            self:SetChargeState( 2 )
        else
            self:SetChargeNextTime( -1 )
        end

        self:OnChargeStep( clip )
        self:OnFullChargeReached( clip )
    else
        self:SetChargeNextTime( stepTime + self.Primary.Delay )
        self:OnChargeStep( clip )
    end

    local chargeStepSound = primary.ChargeStepSound

    -- Charge step sound
    if chargeStepSound ~= "" then
        local chargeStepPitchMinStart = primary.ChargeStepPitchMinStart
        local chargeStepPitchMaxStart = primary.ChargeStepPitchMaxStart
        local chargeStepPitchMinEnd = primary.ChargeStepPitchMinEnd
        local chargeStepPitchMaxEnd = primary.ChargeStepPitchMaxEnd

        local pitchMin = chargeStepPitchMinStart
        local pitchMax = chargeStepPitchMaxStart

        if chargeStepPitchMinStart ~= chargeStepPitchMinEnd or chargeStepPitchMaxStart ~= chargeStepPitchMaxEnd then
            local frac = primary.ChargeStepPitchEase( clip / clipMax )
            pitchMin = Lerp( frac, chargeStepPitchMinStart, chargeStepPitchMinEnd )
            pitchMax = Lerp( frac, chargeStepPitchMaxStart, chargeStepPitchMaxEnd )
        end

        local pitch = pitchMin == pitchMax and pitchMin or math.Rand( pitchMin, pitchMax )

        self:EmitSound( chargeStepSound, 75, pitch, primary.ChargeStepVolume )
    end
end

function SWEP:ReleaseThinkInternal()
    local now = CurTime()
    local stepTime = self:GetChargeNextTime()
    if stepTime == -1 then return end
    if now < stepTime then return end

    local clip = self:Clip1() - 1

    self:SetClip1( clip )
    self:FireWeapon( 1 )

    if clip <= 0 then
        self:SetReleasing( false )
        self:SetChargeNextTime( -1 )
    else
        self:SetChargeNextTime( stepTime + self.Primary.BurstDelay )
    end
end

function SWEP:DoChargeRecoil()
    if CLIENT then return end

    local primary = self.Primary
    local recoilCharging = primary.RecoilCharging
    local mult = recoilCharging.Mult
    if mult <= 0 then return end

    local now = CurTime()
    local nextChargeRecoil = self._nextChargeRecoil or 0

    if now >= nextChargeRecoil then
        self:ApplyRecoil( recoilCharging, mult * self:Clip1() / primary.ClipSize )
        self._nextChargeRecoil = now + primary.RecoilChargingInterval
    end
end

function SWEP:UpdateChargeSprite()
    local primary = self.Primary
    local chargeSpriteInfo = primary.ChargeSprite
    if not chargeSpriteInfo.Enabled then return end

    local clip = self:Clip1()
    local clipMax = primary.ClipSize
    local frac = clip / clipMax

    local alphaStart = chargeSpriteInfo.AlphaStart
    local alphaEnd = chargeSpriteInfo.AlphaEnd
    local alpha = Lerp( frac, alphaStart, alphaEnd )

    if CLIENT then
        local sizeStart = chargeSpriteInfo.SizeStart
        local sizeEnd = chargeSpriteInfo.SizeEnd
        local size = Lerp( frac, sizeStart, sizeEnd )

        chargeSpriteInfo.Size = size
        chargeSpriteInfo.Color.a = alpha

        return
    end

    local chargeSprite = self:GetChargeSprite()
    if not IsValid( chargeSprite ) then return end

    local scaleStart = chargeSpriteInfo.ScaleStart
    local scaleEnd = chargeSpriteInfo.ScaleEnd
    local scale = Lerp( frac, scaleStart, scaleEnd )

    chargeSprite:SetSaveValue( "scale", scale )
    chargeSprite:SetKeyValue( "renderamt", alpha )
end


if CLIENT then
    local function setSpriteNoDraw( wep, noDraw )
        local chargeSprite = wep:GetChargeSprite()

        if IsValid( chargeSprite ) then
            chargeSprite:SetNoDraw( noDraw )
        end
    end


    function SWEP:PreDrawViewModel( vm )
        setSpriteNoDraw( self, true ) -- Hide world sprite when drawing viewmodel

        if self:IsCharging() then
            self:DrawChargeSpriteVM( vm )
        end
    end

    function SWEP:DrawWorldModel()
        -- Show world sprite when charging and drawing worldmodel
        if self:IsCharging() then
            setSpriteNoDraw( self, false )
        end

        BaseClass.DrawWorldModel( self )
    end

    function SWEP:DrawChargeSpriteVM( vm )
        local chargeSpriteInfo = self.Primary.ChargeSprite
        if not chargeSpriteInfo.Enabled then return end

        local mat = self._chargeSpriteMaterialVM

        if not mat then
            mat = Material( chargeSpriteInfo.MatVM )
            self._chargeSpriteMaterialVM = mat
        end

        local pos = vm:LocalToWorld( chargeSpriteInfo.OffsetVM )
        local size = chargeSpriteInfo.Size or 0

        render.SetMaterial( mat )
        render.DrawSprite( pos, size, size, chargeSpriteInfo.Color )
    end
end


----- PRIVATE FUNCTIONS -----

if FindMetaTable( "Player" ).SetMoveSpeedMultiplier then
    -- Utility function from cfc_pvp_movespeed
    setMovementMult = function( ply, mult )
        ply:SetMoveSpeedMultiplier( mult )
    end
else
    local baseRunSpeed
    local baseWalkSpeed

    setMovementMult = function( ply, mult )
        if not baseRunSpeed then -- Could be more accurate, but should work well enough to cover standard Sandbox and TTT.
            baseRunSpeed = ply:GetRunSpeed()
            baseWalkSpeed = ply:GetWalkSpeed()
        end

        ply:SetRunSpeed( baseRunSpeed * mult )
        ply:SetWalkSpeed( baseWalkSpeed * mult )
    end
end

tryApplyChargedMovementMult = function( wep, reset )
    if CLIENT then return end

    local movementMult = wep.Primary.MovementMultWhenCharging
    if movementMult == 1 then return end

    local owner = wep:GetOwner()
    if not IsValid( owner ) then return end

    if reset then
        setMovementMult( owner, 1 )
    else
        setMovementMult( owner, movementMult )
    end
end

createSpriteEnt = function( matPath, color, framerate, scale )
    local sprite = ents.Create( "env_sprite" )

    sprite:SetPos( Vector( 0, 0, 0 ) )
    sprite:SetMoveType( MOVETYPE_NONE )

    sprite:SetSaveValue( "rendermode", RENDERMODE_WORLDGLOW )
    sprite:SetSaveValue( "model", matPath .. ".vmt" )
    sprite:SetSaveValue( "framerate", framerate )
    sprite:SetSaveValue( "scale", scale )
    sprite:SetSaveValue( "rendercolor", color.r .. " " .. color.g .. " " .. color.b )
    sprite:SetKeyValue( "renderamt", color.a )

    sprite:Spawn()
    sprite:Activate()

    return sprite
end


-- Creates (or returns if already present) the charge sprite entity for world rendering. Expects the sprite to be removed if the weapon's owner changes.
function SWEP:_CreateChargeSprite()
    local curSprite = self:GetChargeSprite()
    if IsValid( curSprite ) then return curSprite end

    local chargeSpriteInfo = self.Primary.ChargeSprite
    if not chargeSpriteInfo.Enabled then return end

    local owner = self:GetOwner()
    if not IsValid( owner ) then return end

    local attachID = owner:LookupAttachment( "anim_attachment_RH" )
    if attachID < 1 then return end

    local sprite = createSpriteEnt( chargeSpriteInfo.Mat, chargeSpriteInfo.Color, chargeSpriteInfo.Framerate, chargeSpriteInfo.ScaleStart )
    self._chargeSprite = sprite

    local attachInfo = owner:GetAttachment( attachID )
    local attachPos = attachInfo.Pos
    local attachAng = attachInfo.Ang

    -- Block normal :SetPreventTransmit() calls to prevent other addons (e.g. buildbox) from breaking the sprite's visuals
    function sprite:SetPreventTransmit()
    end

    function sprite:UpdateTransmitState()
        return TRANSMIT_ALWAYS
    end

    sprite:AddEFlags( EFL_FORCE_CHECK_TRANSMIT )
    sprite:SetPos( LocalToWorld( chargeSpriteInfo.Offset, ANGLE_ZERO, attachPos, attachAng ) )
    sprite:SetParent( owner, attachID )

    self:SetChargeSprite( sprite )

    return sprite
end

function SWEP:_RemoveChargeSprite()
    if CLIENT then return end

    local chargeSprite = self:GetChargeSprite()

    if IsValid( chargeSprite ) then
        chargeSprite:Remove()
        self:SetChargeSprite( game.GetWorld() )
    end
end


----- SETUP -----

if SERVER then
    hook.Add( "PlayerDroppedWeapon", "CFC_PvPWeapons_ChargeGunBase_ResetMovementMult", function( ply, wep )
        if not IsValid( ply ) then return end
        if not IsValid( wep ) then return end
        if not wep.CFCSimpleWeaponCharge then return end
        if wep.Primary.MovementMultWhenCharging == 1 then return end

        setMovementMult( ply, 1 )
    end )
end
