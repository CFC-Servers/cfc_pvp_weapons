AddCSLuaFile( "shared.lua" )

SWEP.PrintName = "Knife"
SWEP.Spawnable = true
SWEP.Category = "CFC"
SWEP.DisableSprintViewSimulation = true

SWEP.m_WeaponDeploySpeed = 2

SWEP.BobScale = 0.25
SWEP.SwayScale = 0.25

SWEP.PrimaryAttackDamage = { 30, 35 }
SWEP.SecondaryAttackDamage = { 65, 70 }

SWEP.PrimaryAttackCooldown = 0.5
SWEP.SecondaryAttackCooldown = 0.75

SWEP.AttackRange = 50

SWEP.ImpactDelay = 0.2
SWEP.ImpactDamageWindow = 0.15

SWEP.ViewModel = "models/weapons/cfc_knife/v_knife.mdl"
SWEP.WorldModel = "models/weapons/cfc_knife/w_knife.mdl"

SWEP.HoldType = "knife"

SWEP.DeployTime = 0.6

SWEP.AttackHullAABB = {
    Vector( -10, -5, -5 ),
    Vector( -10,  5,  5 )
}

SWEP.Primary = {
    ClipSize = -1,
    DefaultClip = -1,
    Automatic = true,
    Ammo = "none"
}

SWEP.Secondary = SWEP.Primary

SWEP.Sounds = {
    HitPlayer = { "weapons/knife/knife_hit1.wav", "weapons/knife/knife_hit2.wav", "weapons/knife/knife_hit3.wav", "weapons/knife/knife_hit4.wav" },
    Swing = { "weapons/knife/knife_slash1.wav", "weapons/knife/knife_slash2.wav" },
    HitWorld = { "weapons/knife/knife_hitwall1.wav" },
}

function SWEP:EmitRandomSound( sounds )
    self:EmitSound( sounds[math.random( 1, #sounds )] )
end

function SWEP:Initialize()
    self:SetHoldType( self.HoldType )
end

function SWEP:IsBackstab( hitEnt )
    if not hitEnt:IsPlayer() then return false end

    local ownerAng = self:GetOwner():EyeAngles()
    ownerAng.p = 0
    ownerAng = ownerAng:Forward()

    local targetAng = hitEnt:EyeAngles()
    targetAng.p = 0
    targetAng = targetAng:Forward()

    return targetAng:Dot( ownerAng ) >= 0.7
end

function SWEP:GetDamage( backstab )
    local damageTbl = self.nextAttackDamage
    local damage = damageTbl[math.random( 1, #damageTbl )]

    return backstab and damage * 3 or damage
end

function SWEP:Think()
    if not IsFirstTimePredicted() then return end
    local ct = CurTime()

    local shouldTryAttack = self.nextAttackTime and ct > self.nextAttackTime and ct < self.nextAttackTime + self.ImpactDamageWindow

    if not shouldTryAttack then return end

    local owner = self:GetOwner()

    owner:LagCompensation( true )
    local shootPos = owner:GetShootPos()
    local eyeAng = owner:EyeAngles()
    local dir = eyeAng:Forward()

    local traceInfo = {
        start  = shootPos,
        endpos = shootPos + dir * self.AttackRange,
        mins   = self.AttackHullAABB[1]:Rotate( eyeAng ),
        maxs   = self.AttackHullAABB[2]:Rotate( eyeAng ),
        filter = owner
    }

    local traceResult = util.TraceHull( traceInfo )

    local backstabbed = IsValid( traceResult.Entity ) and self:IsBackstab( traceResult.Entity )
    owner:LagCompensation( false )

    if not traceResult.Hit then return end
    local hitEnt = traceResult.Entity

    local sounds = self.Sounds.HitWorld
    if IsValid( hitEnt ) then
        if hitEnt:IsPlayer() or hitEnt:IsNPC() then sounds = self.Sounds.HitPlayer end
        if SERVER then
            local damageInfo = DamageInfo()
            damageInfo:SetDamage( self:GetDamage( backstabbed ) )
            damageInfo:SetAttacker( owner )
            damageInfo:SetInflictor( self )
            damageInfo:SetDamageForce( dir * 15000 )
            damageInfo:SetDamagePosition( traceResult.HitPos )

            hitEnt:TakeDamageInfo( damageInfo )
        end
    else
        if CLIENT then
            util.Decal( "ManhackCut", traceResult.HitPos + traceResult.HitNormal, traceResult.HitPos - traceResult.HitNormal )
        end
    end

    self:EmitRandomSound( sounds )

    self.nextAttackTime = nil
end

function SWEP:DoAttack( damage, cooldown )
    local ct = CurTime()

    self.nextAttackTime = ct + self.ImpactDelay
    self.nextAttackDamage = damage
    self:SetNextPrimaryFire( ct + cooldown )
    self:SetNextSecondaryFire( ct + cooldown )

    self:EmitRandomSound( self.Sounds.Swing )
    self:GetOwner():SetAnimation( PLAYER_ATTACK1 )
end

function SWEP:PrimaryAttack()
    self:DoAttack( self.PrimaryAttackDamage, self.PrimaryAttackCooldown )
    local vm = self:GetOwner():GetViewModel()
    local attacks = { "midslash1", "midslash2" }
    vm:SendViewModelMatchingSequence( vm:LookupSequence( attacks[math.random( 1, 2 )] ) )
    vm:ResetSequence( attacks[math.random( 1, 2 )] )
end

function SWEP:SecondaryAttack()
    self:DoAttack( self.SecondaryAttackDamage, self.SecondaryAttackCooldown )
    local vm = self:GetOwner():GetViewModel()
    vm:SendViewModelMatchingSequence( vm:LookupSequence( "stab" ) )
end
