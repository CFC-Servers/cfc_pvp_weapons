AddCSLuaFile()

DEFINE_BASECLASS( "cfc_charge_gun_base" )
SWEP.Base = "cfc_charge_gun_base"

-- UI stuff

SWEP.PrintName = "Trash Blaster"
SWEP.Category = "CFC"

SWEP.Slot = 4
SWEP.Spawnable = true

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

    PropMass = 8, -- -1 will use the model's default mass.
    PropSpeedMin = 1000, -- Minimum prop speed.
    PropSpeedMax = 1300, -- Maximum prop speed.
    PropStartFadeDelay = 3, -- Delay before props start fading.
    PropFadeDuration = 1, -- Duration of prop fade. 0 to delete instantly.
    PropNocollideOnImpact = true, -- Nocollide props on impact.
    PropModels = {
        "models/props_junk/garbage_bag001a.mdl",
        "models/props_combine/breenglobe.mdl",
        "models/props_interiors/pot01a.mdl",
        "models/props_interiors/pot02a.mdl",
        "models/props_junk/cinderblock01a.mdl",
        "models/props_junk/plasticbucket001a.mdl",
        "models/props_wasteland/prison_lamp001c.mdl",
        "models/props_combine/breenclock.mdl",
        "models/props_lab/cactus.mdl",
        "models/props_c17/playgroundTick-tack-toe_block01a.mdl",
    },

    PumpAction = false, -- Optional: Tries to pump the weapon between shots
    PumpSound = "Weapon_Shotgun.Special1", -- Optional: Sound to play when pumping

    Delay = 0.15, -- Delay between each buildup of charge, use 60 / x for RPM (Rounds per minute) values
    BurstEnabled = true, -- When releasing the charge, decides whether to burst-fire the weapon once per unit ammo, or to expend the full charge in one fire call
    BurstDelay = 0.075, -- Burst only: the delay between shots during a burst
    Cooldown = 3, -- Cooldown to apply once the charge is expended
    OverchargeDelay = false, -- Once at full charge, it takes this long before overcharge occurs. False to disable.

    Range = 300, -- The range at which the weapon can hit a plate with a diameter of <Accuracy> units
    Accuracy = 24, -- The reference value to use for the previous option, 12 = headshots, 24 = bodyshots

    RangeModifier = 0.85, -- The damage multiplier applied for every 1000 units a bullet travels, e.g. 0.85 for 2000 units = 0.85 * 0.85 = 72% of original damage

    Recoil = {
        MinAng = Angle( 1, -0.3, 0 ), -- The minimum amount of recoil punch per shot
        MaxAng = Angle( 1.2, 0.3, 0 ), -- The maximum amount of recoil punch per shot
        Punch = 0.2, -- The percentage of recoil added to the player's view angles, if set to 0 a player's view will always reset to the exact point they were aiming at
        Ratio = 0.4 -- The percentage of recoil that's translated into the viewmodel, higher values cause bullets to end up above the crosshair
    },

    Reload = { -- Remnant of simple_base, leave as-is
        Time = 0,
        Amount = 1,
        Shotgun = false,
        Sound = ""
    },

    Sound = "doors/vent_open3.wav", -- Firing sound
    TracerName = "", -- Tracer effect, leave blank for no tracer

    ChargeSound = "npc/combine_gunship/engine_rotor_loop1.wav",
    ChargeStepSound = "",
    ChargeStepPitchMin = 80,
    ChargeStepPitchMax = 90,
}

SWEP.ViewOffset = Vector( 0, 0, 0 ) -- Optional: Applies an offset to the viewmodel's position


if CLIENT then
    function SWEP:PrimaryAttack()
        -- Do nothing
    end

    return
end


function SWEP:Initialize()
    BaseClass.Initialize( self )

    self._props = {}
end

function SWEP:OnRemove()
    BaseClass.OnRemove( self )

    for _, prop in ipairs( self._props ) do
        if prop:IsValid() then
            timer.Remove( "CFC_TrashBlaster_StartFadingProp_" .. prop:EntIndex() )
            timer.Remove( "CFC_TrashBlaster_FadeProp_" .. prop:EntIndex() )
            prop:Remove()
        end
    end

    self._props = {}
end

function SWEP:FireWeapon( chargeAmount )
    if chargeAmount > 1 then
        for _ = 1, chargeAmount do
            self:FireWeapon( 1 )
        end

        return
    end

    local owner = self:GetOwner()
    if not IsValid( owner ) then return end

    local speed = math.Rand( self.Primary.PropSpeedMin, self.Primary.PropSpeedMax )
    local mass = self.Primary.PropMass
    local models = self.Primary.PropModels

    local dir = self:SpreadDirection( owner:GetAimVector() )
    local propPos

    if self:IsCloseToWall() then
        propPos = owner:GetShootPos()
    else
        propPos = owner:GetShootPos()
        local ownerVel = owner:GetVelocity()
        local velAccount = ownerVel * FrameTime() * 5

        velAccount = dir * math.Max( velAccount:Dot( dir ), 0 )
        propPos = propPos + dir * 30 + velAccount
    end

    propPos = propPos + dir:Angle():Right() * 7

    local prop = ents.Create( "prop_physics" )
    prop._cfcPropGun_Owner = owner
    prop:SetModel( models[math.random( 1, #models )] )
    prop:SetPos( propPos )
    prop:SetAngles( Angle(
        math.Rand( -180, 180 ),
        math.Rand( -180, 180 ),
        math.Rand( -180, 180 )
    ) )
    prop:SetCollisionGroup( COLLISION_GROUP_INTERACTIVE_DEBRIS )
    prop:Spawn()

    prop:EmitSound( self.Primary.Sound )
    prop:SetPhysicsAttacker( owner, 1000 )

    if self.Primary.PropNocollideOnImpact then
        prop._cfcPropGun_NocollideOnImpact = true
    end

    local physObj = prop:GetPhysicsObject()

    if mass > 0 then
        physObj:SetMass( mass )
    end

    physObj:SetVelocity( dir * speed )

    table.insert( self._props, prop )

    -- Fade prop later
    timer.Create( "CFC_TrashBlaster_StartFadingProp_" .. prop:EntIndex(), self.Primary.PropStartFadeDelay, 1, function()
        if not prop:IsValid() then return end

        prop:SetCollisionGroup( COLLISION_GROUP_WORLD )

        local fadeDuration = self.Primary.PropFadeDuration

        if fadeDuration <= 0 then
            table.RemoveByValue( self._props, prop )
            prop:Remove()

            return
        end

        local fadeStep = 0.1
        local numFadeSteps = math.ceil( fadeDuration / fadeStep )
        local stepsLeft = numFadeSteps

        prop:SetRenderMode( RENDERMODE_TRANSCOLOR )

        timer.Create( "CFC_TrashBlaster_FadeProp_" .. prop:EntIndex(), fadeStep, numFadeSteps, function()
            if not prop:IsValid() then return end

            stepsLeft = stepsLeft - 1

            if stepsLeft <= 0 then
                table.RemoveByValue( self._props, prop )
                prop:Remove()
            else
                prop:SetColor( Color( 255, 255, 255, 255 * stepsLeft / numFadeSteps ) )
            end
        end )
    end )
end

function SWEP:IsCloseToWall()
    local owner = self:GetOwner()
    if not IsValid( owner ) then return false end

    local tr = util.TraceLine( {
        start = owner:GetShootPos(),
        endpos = owner:GetShootPos() + owner:GetAimVector() * 40,
        filter = owner,
        mask = MASK_SHOT_HULL,
    } )

    return tr.Hit
end

function SWEP:SpreadDirection( dir )
    local spread = self:GetSpread()[1] -- simple_base returns as a vector
    if spread == 0 then return dir end

    spread = math.deg( spread )

    local ang = dir:Angle()
    local dirAng = Angle( ang.p, ang.y, ang.r )

    dirAng:RotateAroundAxis( ang:Right(), math.Rand( -spread, spread ) )
    dirAng:RotateAroundAxis( ang:Up(), math.Rand( -spread, spread ) )

    return dirAng:Forward()
end
