AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
include( "shared.lua" )

-- local breakableClasses = {
--     prop_physics = true,
--     sent_spawnpoint = true
-- }

local IsValid = IsValid

if file.Exists( "includes/modules/mixpanel.lua", "LUA" ) then
    require( "mixpanel" )
end

local function mixpanelTrackEvent( eventName, ply, data )
    if not Mixpanel then return end
    Mixpanel:TrackPlyEvent( eventName, ply, data )
end

function ENT:Initialize()

    local owner = self:GetOwner()

    if not IsValid( owner ) then
        self:Remove()
        return
    end

    mixpanelTrackEvent( "Shaped charge placed", self:GetOwner() )

    owner.plantedCharges = owner.plantedCharges or 0
    owner.plantedCharges = owner.plantedCharges + 1

    self.bombHealth  = GetConVar( "cfc_shaped_charge_chargehealth" ):GetInt()
    self.bombTimer   = GetConVar( "cfc_shaped_charge_timer" ):GetInt()
    self.blastDamage = GetConVar( "cfc_shaped_charge_blastdamage" ):GetInt()
    self.blastRange  = GetConVar( "cfc_shaped_charge_blastrange" ):GetInt()
    self.traceRange  = GetConVar( "cfc_shaped_charge_tracerange" ):GetInt()

    self:SetModel( "models/weapons/w_c4_planted.mdl" )
    self:PhysicsInit( SOLID_VPHYSICS )
    self:SetSolid( SOLID_VPHYSICS )
    self:DrawShadow( false )
    self:SetCollisionGroup( COLLISION_GROUP_WEAPON )

    self:PhysWake()

    self:CreateLight()

    self.explodeTime = CurTime() + self.bombTimer

    self:EmitSound( "items/ammocrate_close.wav", 100, 100, 1, CHAN_STATIC )
    self:EmitSound( "npc/roller/blade_cut.wav", 100, 100, 1, CHAN_STATIC )

    self:SetNWFloat( "bombInitiated", CurTime() )

    self.spawnTime = CurTime()
    self:bombVisualsTimer()
end

function ENT:OnTakeDamage( dmg )
    if dmg:IsDamageType( DMG_BURN ) then return end -- Prevents burning props strat

    self.bombHealth = self.bombHealth - dmg:GetDamage()
    if self.bombHealth <= 0 then
        if not IsValid( self ) then return end

        local attacker = dmg:GetAttacker()
        local weaponClass = "invalid weapon"

        if IsValid( attacker ) and attacker:IsPlayer() then
            local weapon = attacker:GetActiveWeapon()
            if IsValid( weapon ) then
                weaponClass = weapon:GetClass()
            end
        else
            weaponClass = attacker:GetClass()
        end
        mixpanelTrackEvent( "Shaped charge broken", self:GetOwner(), { owner = self:GetOwner(), breaker = dmg:GetAttacker(), weapon = weaponClass } )

        local effectdata = EffectData()
        effectdata:SetOrigin( self:GetPos() )
        effectdata:SetMagnitude( 8 )
        effectdata:SetScale( 1 )
        effectdata:SetRadius( 16 )

        util.Effect( "Sparks", effectdata )

        self:EmitSound( "npc/roller/mine/rmine_taunt1.wav", 100, 100, 1, CHAN_STATIC )
        self:EmitSound( "doors/vent_open1.wav", 100, 100, 1, CHAN_STATIC )

        self:Remove()
    end
    local effectdata = EffectData()
    effectdata:SetOrigin( self:GetPos() )
    effectdata:SetScale( 0.5 )
    effectdata:SetMagnitude( 1 )

    util.Effect( "Sparks", effectdata )

    self:EmitSound( "Plastic_Box.Break", 100, 100, 1, CHAN_WEAPON )
    self:EmitSound( "npc/roller/code2.wav", 100, 100, 1, CHAN_WEAPON )
end

function ENT:OnRemove()
    local owner = self:GetOwner()

    if not IsValid( owner ) then
        self:Remove()
        return
    end

    owner.plantedCharges = owner.plantedCharges or 0
    owner.plantedCharges = owner.plantedCharges - 1
    if owner.plantedCharges <= 0 then
        owner.plantedCharges = nil
    end
end

function ENT:Think()
    if not IsValid( self ) then return end
    if not IsValid( self:GetOwner() ) then self:Remove() end

    if self.explodeTime <= CurTime() then
        self:Explode()
    end
end

function ENT:Explode()
    if not IsValid( self:GetOwner() ) then self:Remove() end

    local props = ents.FindAlongRay( self:GetPos(), self:GetPos() + self.traceRange * -self:GetUp() )

    local count = 0
    for _, prop in pairs( props ) do
        if self:CanDestroyProp( prop ) then
            prop:Remove()
            count = count + 1
        end
    end

    mixpanelTrackEvent( "Shaped charge props broken", self:GetOwner(), { count = count } )

    util.BlastDamage( self, self:GetOwner(), self:GetPos(), self.blastRange, self.blastDamage )

    local effectdata = EffectData()
    effectdata:SetOrigin( self:GetPos() )
    effectdata:SetNormal( -self:GetUp() )
    effectdata:SetRadius( 3 )

    util.Effect( "AR2Explosion", effectdata )
    util.Effect( "Explosion", effectdata )

    self:EmitSound( "npc/strider/strider_step4.wav", 100, 100, 1, CHAN_STATIC )
    self:EmitSound( "weapons/mortar/mortar_explode2.wav", 500, 100, 1, CHAN_WEAPON )

    self:Remove()
end

function ENT:RunCountdownEffects()
    self.bombLight:SetKeyValue( "brightness", 2 )
    timer.Simple( 0.2, function()
        if not IsValid( self ) then return end

        self.bombLight:SetKeyValue( "brightness", 0 )
    end )

    self:EmitSound( "weapons/c4/c4_beep1.wav", 85, 100, 1, CHAN_STATIC )
    self:bombVisualsTimer()
end

function ENT:bombVisualsTimer()
    local timePassed = CurTime() - self.spawnTime
    local timerDelay = math.Clamp( self.bombTimer / timePassed - 1, 0.13, 1 )

    timer.Simple( timerDelay, function()
        if not IsValid( self ) then return end
        self:RunCountdownEffects()
    end )
end

function ENT:CreateLight()
    self.bombLight = ents.Create( "light_dynamic" )
    self.bombLight:SetPos( self:GetPos() + self:GetUp() * 10 )
    self.bombLight:SetKeyValue( "_light", 255, 0, 0, 200 )
    self.bombLight:SetKeyValue( "style", 0 )
    self.bombLight:SetKeyValue( "distance", 255 )
    self.bombLight:SetKeyValue( "brightness", 0 )
    self.bombLight:SetParent( self )
    self.bombLight:Spawn()
end

function ENT:CanDestroyProp( prop )
    if not IsValid( prop ) then return false end
    if not IsValid( prop:CPPIGetOwner() ) then return false end
    --if not breakableClasses[prop:GetClass()] then return false end

    if not IsValid( self:GetOwner() ) then return false end
    local shouldDestroy = hook.Run( "CFC_SWEP_ShapedCharge_CanDestroyQuery", self, prop )

    if shouldDestroy ~= false then return true end

    return false
end
