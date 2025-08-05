AddCSLuaFile()

DEFINE_BASECLASS( "cfc_simple_base_throwing" )
SWEP.Base = "cfc_simple_base_throwing"

-- UI stuff

SWEP.PrintName = "Super Cinder Block"
SWEP.Category = "CFC"
SWEP.UseHands = true

SWEP.AutoSwitchTo = true
SWEP.AutoSwitchFrom = false
SWEP.Weight = 1000
SWEP.Slot = 1
SWEP.ViewModel = Model( "models/weapons/c_grenade.mdl" )
SWEP.Spawnable = true
SWEP.AdminOnly = true
SWEP.Instructions = "It's just begging you to hit someone in the head!\nEventually despawns if not picked up."

if CLIENT then -- killicon, HUD icon and language 'translation'
    CFCPvPWeapons.CL_SetupSwep( SWEP, "cfc_super_cinder_block", "materials/vgui/hud/cfc_super_cinder_block.png" )
end

SWEP.IdleHoldType = "slam"
SWEP.ThrowingHoldType = "melee"

SWEP.ProjectileClass = "cfc_super_cinderblock_projectile"
SWEP.InfiniteAmmo = false

SWEP.ModelScale = 1
SWEP.ModelMaterial = "models/cfc/gold/gold_player"
SWEP.ThrowVelMul = 3

SWEP.WorldModel = "models/props_debris/concrete_cynderblock001.mdl"
SWEP.OffsetWorldModel = true
SWEP.WMPosOffset = Vector( 8, 2, 0 )
SWEP.WMAngOffset = Angle( 0, 180, -90 )

SWEP.HeldModel = SWEP.WorldModel
SWEP.HeldModelPosOffset = Vector( -22, 8, -22 )
SWEP.HeldModelAngOffset = Angle( 0, -80, 0 )

SWEP.Primary.ThrowAct = { ACT_VM_PULLBACK_HIGH, ACT_VM_THROW }
SWEP.Primary.LobAct = { ACT_VM_PULLBACK_LOW, ACT_VM_HAULBACK }
SWEP.Primary.RollAct = { ACT_VM_PULLBACK_LOW, ACT_VM_SECONDARYATTACK }

SWEP.IsCFCSuperCinderBlock = true

SWEP.CFC_FirstTimeHints = {
    {
        Message = "Brick'em",
        Sound = "ambient/water/drip1.wav",
        Duration = 15,
    },
}

function SWEP:CreateEntity()
    local ent = ents.Create( self.ProjectileClass )
    ent:SetThrower( self:GetOwner() )
    ent:Spawn()
    return ent
end

function SWEP:CustomAmmoDisplay()
    return { Draw = false }
end

function SWEP:EmitThrowSound()
    self:EmitSound( "WeaponFrag.Throw", 100, 70, 1, CHAN_STATIC, SND_CHANGE_PITCH )
    self:EmitSound( "WeaponFrag.Throw", 100, 40, 1, CHAN_STATIC, SND_CHANGE_PITCH )
    util.ScreenShake( self:WorldSpaceCenter(), 10, 20, 0.1, 1500 )
    util.ScreenShake( self:WorldSpaceCenter(), 20, 20, 0.5, 500 )
end

if not SERVER then return end

local function collideEffects( ent, data )
    local nextSound = ent.cfcsupercinderblock_nextcollidesound or 0
    if nextSound > CurTime() then return end
    ent.cfcsupercinderblock_nextcollidesound = CurTime() + 0.05

    local speed = data.Speed
    if speed < 100 then return end

    local pitch = 180 - ( speed / 30 )
    ent:EmitSound( "Canister.ImpactSoft", 80, pitch, 1, CHAN_ITEM, bit.bor( SND_CHANGE_PITCH, SND_CHANGE_VOL ) )
    ent:EmitSound( "physics/metal/metal_canister_impact_hard" .. math.random( 1, 3 ) .. ".wav", 90, math.random( 20, 30 ), 0.5, CHAN_STATIC )

    local effectdata = EffectData()
    effectdata:SetOrigin( data.HitPos )
    effectdata:SetNormal( -data.HitNormal )
    effectdata:SetScale( 1 + speed / 2000 )
    effectdata:SetMagnitude( 1 )
    effectdata:SetRadius( speed / 10 )
    util.Effect( "Sparks", effectdata )
end

function SWEP:Initialize()
    BaseClass.Initialize( self )

    self:AddCallback( "PhysicsCollide", collideEffects )

    local physObj = self:GetPhysicsObject()
    if not IsValid( physObj ) then return end

    physObj:SetMass( 5000 )
    physObj:SetMaterial( "Rubber" )
end


function SWEP:OwnerChanged()
    timer.Simple( 0, function()
        if not IsValid( self ) then return end
        if not IsValid( self:GetOwner() ) then
            self:EmitSound( "Canister.ImpactSoft", 80, math.random( 80, 90 ), 1, CHAN_STATIC, bit.bor( SND_CHANGE_PITCH, SND_CHANGE_VOL ) )
            self:EmitSound( "physics/metal/metal_canister_impact_hard" .. math.random( 1, 3 ) .. ".wav", 90, math.random( 20, 30 ), 0.5, CHAN_STATIC )
        else
            self:EmitSound( "Canister.ImpactSoft", 80, math.random( 100, 110 ), 1, CHAN_STATIC, bit.bor( SND_CHANGE_PITCH, SND_CHANGE_VOL ) )
            self:EmitSound( "physics/metal/metal_canister_impact_hard" .. math.random( 1, 3 ) .. ".wav", 90, math.random( 30, 40 ), 0.5, CHAN_STATIC )
        end
    end )
end

hook.Add( "PlayerCanPickupWeapon", "cfc_super_cinder_block_nodoublepickup", function( ply, weapon )
    if not weapon.IsCFCSuperCinderBlock then return end
    if ply:HasWeapon( "cfc_super_cinder_block" ) then
        if ply:KeyDown( IN_USE ) and ply:GetEyeTrace().Entity == weapon then -- they already have one, make em switch to it!
            ply:SelectWeapon( "cfc_super_cinder_block" )
        end
        return false
    end
end )

hook.Add( "PlayerDeath", "cfc_super_cinder_block_dropondeath", function( ply )
    local superBlock = ply:GetWeapon( "cfc_super_cinder_block" )
    if not IsValid( superBlock ) then return end

    if not superBlock:GetThrowableInHand() then return end -- was just thrown, the block is actually in the air!

    local newWep = ents.Create( "cfc_super_cinder_block" )
    if not IsValid( newWep ) then return end

    newWep:SetPos( ply:GetShootPos() )
    newWep:SetAngles( AngleRand() )
    newWep:Spawn()

    newWep:SetCollisionGroup( COLLISION_GROUP_INTERACTIVE_DEBRIS )
    timer.Simple( 0, function()
        if not IsValid( newWep ) then return end
        newWep:EmitSound( "physics/concrete/concrete_impact_hard3.wav", 90, 40, 1, CHAN_STATIC )
        newWep:EmitSound( "physics/metal/metal_canister_impact_hard" .. math.random( 1, 3 ) .. ".wav", 90, math.random( 10, 15 ), 1, CHAN_STATIC )
    end )

    local cur = CurTime()
    newWep.cfc_supercinderblock_lastdrop = cur

    timer.Simple( math.random( 240, 280 ), function()
        if not IsValid( newWep ) then return end
        if IsValid( newWep:GetOwner() ) or IsValid( newWep:GetParent() ) then return end
        if newWep.cfc_supercinderblock_lastdrop ~= cur then return end

        SafeRemoveEntity( newWep )
    end )
end )

hook.Add( "PlayerCanPickupWeapon", "cfc_super_cinder_block_noinstantpickup", function( _, weapon )
    if not weapon.cfcsupercinderblock_nextpickup then return end
    if weapon.cfcsupercinderblock_nextpickup > CurTime() then return false end
end )