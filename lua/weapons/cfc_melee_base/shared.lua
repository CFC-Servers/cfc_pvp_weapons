AddCSLuaFile()

-- General info
SWEP.Author = "Redox"
SWEP.Purpose = "CFC Sweps."
SWEP.PrintName = "BASESWEP"
SWEP.Category = "CFC"

-- Visuals
SWEP.UseHands = true
SWEP.HoldType = "knife"
SWEP.DrawCrosshair = true
SWEP.IconOverride = ""
SWEP.ViewModel		= "models/weapons/cstrike/c_knife_t.mdl"
SWEP.WorldModel		= "models/weapons/w_knife_t.mdl"
SWEP.Slot = 3
SWEP.SlotPos = 1
SWEP.DrawWeaponInfoBox = true

-- Sounds
SWEP.HitSounds = {
    "weapons/knife/knife_hit1.wav",
    "weapons/knife/knife_hit2.wav",
    "weapons/knife/knife_hit3.wav",
    "weapons/knife/knife_hit4.wav"
}
SWEP.BackStabSound = "weapons/knife/knife_stab.wav"
SWEP.HitWorldSound = "weapons/knife/knife_hitwall1.wav"
SWEP.SwingSound = "weapons/knife/knife_swing_miss1.wav"
SWEP.DeploySound = "weapons/knife/knife_deploy.wav"
SWEP.HolsterSound = ""

-- Functionals
SWEP.Slot = 1
SWEP.SlotPos = 1
SWEP.Spawnable = true
SWEP.AdminSpawnable = false
SWEP.AdminOnly = false

-- Ammo and such
-- Primary
SWEP.Primary.ClipSize = 1
SWEP.Primary.DefaultClip = 1
SWEP.Primary.Ammo = ""
SWEP.Primary.Automatic = true

-- Secondary
SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = true
SWEP.Secondary.Ammo = ""

-- Stats (damage and such)
SWEP.PrimaryDamage = 25
SWEP.SecondaryDamage = 50
SWEP.BackStabMultiplier = 3 -- The damage multiplier on backstabs
SWEP.DamageRandom = 4 --Random +- added to the damage to make it more organic

SWEP.ShouldBackstab = true -- If the swep is able to deal double damage on backstabs
SWEP.Range = 70 -- The range of the melee attack

SWEP.PrimaryFireRate = 0.5 -- Interval the pimary attack can be used
SWEP.SecondaryFireRate = 1 -- Interval the secondary attack can be used
SWEP.BackStabFireRateMult = 1.5 -- The interval multiplier after backstabbing someone

function SWEP:Initialize()
    self:SetHoldType( self.HoldType )
    return true
end

function SWEP:Deploy()
    self:EmitSound( self.DeploySound )
    self:SendWeaponAnim( ACT_VM_DRAW )
    return true
end

function SWEP:Holster()
    self:EmitSound( self.HolsterSound )
    return true
end

function SWEP:EntityFaceBack( ent )
    local angle = self:GetOwner():GetAngles().y - ent:GetAngles().y
    if angle < -180 then angle = 360 + angle end
    if angle <= 90 and angle >= -90 then return true end
    return false
end

function SWEP:DoAttack( secondary ) -- true for secondary attack / "heavy attack"
    local ply = self:GetOwner()
    local curTime = CurTime()
    local traceEndPos = ply:EyePos() + ply:EyeAngles():Forward() * self.Range

    local tr = util.TraceLine({
        start = ply:EyePos(),
        endpos = traceEndPos,
        filter = ply,
    })

    local ent = tr.Entity

    if ent:IsWorld() then
        self:SendWeaponAnim( ACT_VM_MISSCENTER )
        self:SetNextPrimaryFire( curTime + self.PrimaryFireRate )
        self:EmitSound( self.HitWorldSound )
        return true
    end

    if not IsValid( ent ) then
        self:SendWeaponAnim( ACT_VM_MISSCENTER )
        self:SetNextPrimaryFire( curTime + self.PrimaryFireRate )
        self:EmitSound( self.SwingSound )
        return true
    end

    local isBackstab = self:EntityFaceBack( ent )
    local force = ply:GetAimVector():GetNormalized() * 300 * cvars.Number("phys_pushscale", 1)
    local damageInfo = DamageInfo()

    damageInfo:SetAttacker( ply )
    damageInfo:SetInflictor( self )
    damageInfo:SetDamageType( bit.bor( DMG_SLASH , DMG_NEVERGIB ) )
    damageInfo:SetDamageForce( force )
    damageInfo:SetDamagePosition( traceEndPos )

    local damageMultiplier = 1
    local firerateMultiplier = 1
    if isBackstab then
        damageMultiplier = self.BackStabMultiplier
        firerateMultiplier = self.BackStabFireRateMult
    end

    if not secondary then
        damageInfo:SetDamage( ( math.random( -self.DamageRandom, self.DamageRandom ) + self.PrimaryDamage ) * damageMultiplier )
        ent:DispatchTraceAttack( damageInfo, tr, ply:GetAimVector() )

        self:SetNextPrimaryFire( curTime + self.PrimaryFireRate * firerateMultiplier )

        self:EmitSound( self.HitSounds[math.random( #self.HitSounds )] )
    else
        damageInfo:SetDamage( ( math.random( -self.DamageRandom, self.DamageRandom ) + self.SecondaryDamage ) * damageMultiplier )
        ent:DispatchTraceAttack( damageInfo, tr, ply:GetAimVector() )

        self:SetNextPrimaryFire( curTime + self.SecondaryFireRate * firerateMultiplier )

        self:EmitSound( self.BackStabSound )
    end

    self:SetAnimation( PLAYER_ATTACK1 )
    self:SendWeaponAnim( ACT_VM_SECONDARYATTACK )
    return true
end

function SWEP:PrimaryAttack()
    self:DoAttack( false )
end

function SWEP:SecondaryAttack()
    if CurTime() < self:GetNextPrimaryFire() then return end -- Both use primary fire to prevent prim and sec fire at the same time
    self:DoAttack( true )
end

function SWEP:Reload()
    return
end
