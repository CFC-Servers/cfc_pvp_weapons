AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
include( "shared.lua" )

local breakableClasses = {
    prop_physics = true,
    sent_spawnpoint = true
}

if file.Exists( "includes/modules/mixpanel.lua", "LUA" ) then
    require( "mixpanel" )
end

local function mixpanelTrackEvent( eventName, ply, data )
    if not Mixpanel then return end
    Mixpanel:TrackPlyEvent( eventName, ply, data )
end

function ENT:Initialize()

    local owner = self.bombOwner

    if not IsValid( owner ) then
        self:Remove()
        return
    end

    mixpanelTrackEvent( self.swepName .. " placed", self.bombOwner )

    self:SetModel( self.swepModel )
    self:SetModelScale( self.modelScale )
    self:PhysicsInit( SOLID_VPHYSICS )
    self:SetSolid( SOLID_VPHYSICS )
    self:DrawShadow( false )
    self:SetCollisionGroup( COLLISION_GROUP_WEAPON )

    self:SwepPlace( owner )

    if IsColor( self.ColorIdentity ) then 
        self:SetColor( self.ColorIdentity )
    end
    self:PhysWake()

end

function ENT:SwepPlace( owner )
    
    local plantedCharges = owner:GetNWFloat( "plantedShapedCharges", 0 )
    local plantedCharges = plantedCharges + 1 
    owner:SetNWInt( "plantedShapedCharges", plantedCharges )

    local myClass = self:GetClass() 

    self.bombHealth  = GetConVar( myClass .. "_chargehealth" ):GetInt()
    self.bombTimer   = GetConVar( myClass .. "_timer" ):GetInt()
    self.blastDamage = GetConVar( myClass .. "_blastdamage" ):GetInt()
    self.blastRange  = GetConVar( myClass .. "_blastrange" ):GetInt()
    self.traceRange  = GetConVar( myClass .. "_tracerange" ):GetInt()
    self.defuseTime  = GetConVar( myClass .. "_defusetime" ):GetInt() or 0

    self:CreateLight()

    self.explodeTime = CurTime() + self.bombTimer

    self:PlantEffects()

    self:SetNWFloat( "bombInitiated", CurTime() )

    self.spawnTime = CurTime()
    self:bombVisualsTimer()

end

function ENT:PlantEffects()
    self:EmitSound( "items/ammocrate_close.wav", 100, 100, 1, CHAN_STATIC )
    self:EmitSound( "npc/roller/blade_cut.wav", 100, 100, 1, CHAN_STATIC )

end

function ENT:OnTakeDamage( dmg )
    self.bombHealth = self.bombHealth - dmg:GetDamage()
    if self.bombHealth <= 0 then
        self:PropBreak( dmg:GetAttacker() )
    end
    local effectdata = EffectData()
    effectdata:SetOrigin( self:GetPos() )
    effectdata:SetScale( 0.5 )
    effectdata:SetMagnitude( 1 )

    util.Effect( "Sparks", effectdata )

    self:EmitSound( "Plastic_Box.Break", 100, 100, 1, CHAN_WEAPON )
    self:EmitSound( "npc/roller/code2.wav", 100, 100, 1, CHAN_WEAPON )
end

function ENT:PropBreak( attacker, prop )
    if not IsValid( self ) then return end

    local weaponClass = "invalid weapon"

    if IsValid( attacker ) and attacker:IsPlayer() then
        local weapon = attacker:GetActiveWeapon()
        if IsValid( weapon ) then
            weaponClass = weapon:GetClass()
        end
    else
        weaponClass = self:GetClass()
    end
    mixpanelTrackEvent( "Shaped charge broken", self.bombOwner, {owner = self.bombOwner, breaker = attacker, weapon = weaponClass } )

    local effectdata = EffectData()
    effectdata:SetOrigin( self:GetPos() )
    effectdata:SetMagnitude( self.sparkScale )
    effectdata:SetScale( 1 )
    effectdata:SetRadius( 16 )

    util.Effect( "Sparks", effectdata )

    self:EmitSound( "npc/roller/mine/rmine_taunt1.wav", 100, 100, 1, CHAN_STATIC )
    self:EmitSound( "doors/vent_open1.wav", 100, 100, 1, CHAN_STATIC )

    self:Remove()
end

function ENT:OnRemove()
    local owner = self.bombOwner

    if not IsValid( owner ) then
        self:Remove()
        return
    end

    local plantedCharges = owner:GetNWFloat( "plantedShapedCharges", 0 ) 
    local plantedCharges = math.Clamp( plantedCharges - 1, 0, math.huge )
    owner:SetNWFloat( "plantedShapedCharges", plantedCharges  )
end

function ENT:Think()
    if not IsValid( self ) then return end
    if self:GetParent():IsPlayer() then
        if not self:GetParent():Alive() then self:Defuse() return end
    end 

    if self.explodeTime <= CurTime() then
        self:Explode()
    end
end

function ENT:Explode()
    local props = ents.FindAlongRay( self:GetPos(), self:GetPos() + self.traceRange * -self:GetUp() )

    local count = 0
    for _, prop in pairs( props ) do
        if self:CanDestroyProp( prop ) then
            prop:Fire("break",1,0)
            count = count + 1
        elseif prop:IsPlayer() and self.plantableOnPlayers then
            self:ChargeAttackPlayer( prop )
        end
    end

    mixpanelTrackEvent( "Shaped charge props broken", self.bombOwner, { count = count } )

    util.BlastDamage( self, self.bombOwner, self:GetPos(), self.blastRange, self.blastDamage )

    self:chargeExplodeEffects()

    self:Remove()
end

function ENT:ChargeAttackPlayer( ply )
end

function ENT:RunCountdownEffects()
    self.bombLight:SetKeyValue( "brightness", 2 )
    timer.Simple( 0.2, function()
        if not IsValid( self ) then return end

        self.bombLight:SetKeyValue( "brightness", 0 )
    end )

    self:EmitSound( self.countDownSound, 85, self.countDownPitch, 1, CHAN_STATIC )
    self:bombVisualsTimer()
end

function ENT:bombVisualsTimer()
    local timePassed = CurTime() - self.spawnTime
    local timerDelay = math.Clamp( self.bombTimer / timePassed - 1, 0.13, 1 )
    if timePassed > self.bombTimer + -1 then
        self:PreExplodeEffects()
        return
    end

    timer.Simple( timerDelay, function()
        if not IsValid( self ) then return end
        self:RunCountdownEffects()
    end )
end

function ENT:CreateLight()
    local r, g, b = 255, 0, 0
    if IsColor( self.ColorIdentity ) then
        r, g, b = self.ColorIdentity.r, self.ColorIdentity.g, self.ColorIdentity.b
    end
    self.bombLight = ents.Create( "light_dynamic" )
    self.bombLight:SetPos( self:GetPos() + self:GetUp() * 10 )
    self.bombLight:SetKeyValue( "_light", r .. g .. b .. 200 )
    self.bombLight:SetKeyValue( "style", 0 )
    self.bombLight:SetKeyValue( "distance", 255 )
    self.bombLight:SetKeyValue( "brightness", 0 )
    self.bombLight:SetParent( self )
    self.bombLight:Spawn()
end

function ENT:CanDestroyProp( prop )
    if not IsValid( prop ) then return false end
    if not IsValid( prop:CPPIGetOwner() ) then return false end
    if not breakableClasses[prop:GetClass()] then return false end

    if not IsValid( self.bombOwner ) then return false end
    local shouldDestroy = hook.Run( "CFC_SWEP_ShapedCharge_CanDestroyQuery", self, prop )

    if shouldDestroy ~= false then return true end

    return false
end

function ENT:PreExplodeEffects()
    self:EmitSound( "npc/roller/blade_in.wav", 100, 70, 1, CHAN_WEAPON )
end



function ENT:KickAngles()
    local vector = Vector()
    vector:Random( -1, 1 )
    local randComp = vector:Angle() / 100
    self:SetAngles( self.StartDefuseAng + randComp )
end

function ENT:StartDefuse( defuser )
    if not self:CanStartNewDefuse( defuser ) then return end 
    self.StartDefuseAng = self:GetAngles()
    self.NextDefuseSound = CurTime() + 1
    self.DefuseStartTime = CurTime()
    self.DefuseEndTime = CurTime() + self.defuseTime
    self.Defuser = defuser
    defuser.CfcShapedChargeDefusing = self
    self:DefuseThink( defuser )
    self:EmitSound( "Plastic_Box.Strain", 80, 130 )
    self:EmitSound( "common/wpn_select.wav", 80, 130 )
    self:KickAngles()
end

local function PlyTooFast( ply )
    if not IsValid( ply ) then return end
    local vel = ply:GetVelocity()
    return vel:Length() > 65
end

function ENT:CanStartNewDefuse( defuser ) 
    if self.defuseTime <= 0 or not self.defuseTime then return end
    if IsValid( self.Defuser ) then return false end
    if IsValid( defuser.CfcShapedChargeDefusing ) then return false end
    if PlyTooFast( ply ) then return false end
    if defuser:GetEyeTrace().Entity ~= self then return false end
    if not defuser:Alive() then return false end
    return true
end

function ENT:ValidDefuse( defuser )
    if not IsValid( self ) or not IsValid( defuser ) then return false end
    if not defuser:Alive() then return false end
    if not defuser:KeyDown( IN_USE ) then return false end
    if PlyTooFast( ply ) then return false end
    local trace = defuser:GetEyeTraceNoCursor()
    if trace.StartPos:Distance( trace.HitPos ) > 100 then return false end
    if trace.Entity ~= self then return false end
    return true 
end

function ENT:DefuseThink( defuser )
    if self.DefuseEndTime < CurTime() then self:Defuse( defuser, true ) return end
    timer.Simple( 0.1, function() 
        if not IsValid( self ) or not IsValid( defuser ) then return end
        if not self:ValidDefuse( defuser ) then self:DefuseExit( defuser, true ) return end
        self:DefuseThink( defuser ) 
    end )
    if self.NextDefuseSound > CurTime() then return end
    self.NextDefuseSound = CurTime() + math.random( 0.9, 0.3 )
    self:KickAngles()
    self:EmitSound( "weapons/slam/mine_mode.wav", 80, math.random( 145, 155 ) )
end

function ENT:Defuse( defuser )
    self:DefuseExit( defuser )
    self:EmitSound( "npc/roller/blade_in.wav", 90, 110, 1 )

    local Up = self:GetUp()
    local ent = ents.Create('prop_physics')
    ent:SetModel(self:GetModel())
    ent:SetPos( self:GetPos() )
    ent:SetAngles( self:GetAngles() )
    ent:Spawn()
    ent:SetCollisionGroup( 11 )
    ent:SetColor( self.ColorIdentity )
    SafeRemoveEntityDelayed( ent, 45 )
    ent.DoNotDuplicate = true
    
    if self.physMaterial then
        local Obj = ent:GetPhysicsObject()
        Obj:SetMaterial( self.physMaterial )
    end

    self:Remove()
end

function ENT:DefuseExit( defuser, accidental )
    self.DefuseStartTime = nil
    self.DefuseEndTime = nil
    self.Defuser = nil
    if isangle( self.StartDefuseAng ) then 
        self:SetAngles( self.StartDefuseAng )
    end
    if not IsValid( defuser ) then return end
    defuser.CfcShapedChargeDefusing = nil
    if not accidental then return end 
    defuser:EmitSound( "Plastic_Box.Strain", 80, 110 )

end

function ENT:Use( activator, caller, useType, value )
    self:StartDefuse( activator )
end