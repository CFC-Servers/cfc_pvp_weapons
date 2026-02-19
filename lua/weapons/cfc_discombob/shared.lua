AddCSLuaFile()

if CLIENT then
    language.Add( "cfc_discomob_ammo", "Discombobs" )
end

game.AddAmmoType( { name = "cfc_discomob", maxcarry = 5 } )

DEFINE_BASECLASS( "cfc_simple_base_throwing" )
SWEP.Base = "cfc_simple_base_throwing"

SWEP.PrintName = "'Nade (Discombob)"
SWEP.Category = "CFC"

SWEP.Slot = 4
SWEP.Spawnable = true

SWEP.UseHands = true
SWEP.ViewModelFOV = 54
SWEP.ViewModel = Model( "models/weapons/cstrike/c_eq_fraggrenade.mdl" ) -- Funnily enough, both of these are in the gmod vpk.
SWEP.WorldModel = Model( "models/weapons/w_eq_fraggrenade.mdl" ) -- However, the worldmodel's material is not packed, while the viewmodel's material is. Hence it being set in Initialize.

SWEP.IdleHoldType = "slam"
SWEP.ThrowingHoldType = "melee"

SWEP.Primary = {
    Ammo = "cfc_discomob",
    DefaultClip = 50,

    ThrowAct = { ACT_VM_PULLBACK_HIGH, ACT_VM_THROW },
    LobAct = { ACT_VM_PULLBACK_LOW, ACT_VM_HAULBACK },
    RollAct = { ACT_VM_PULLBACK_LOW, ACT_VM_SECONDARYATTACK },

    RadiusMult = 1.25, -- Affects the explosion radius
    StrengthMult = 1.25, -- Affects the knockback strength against other players and props
    StrengthMultSelf = 1.25, -- Affects the knockback strength against the player who threw it
}

SWEP.ThrowCooldown = 0 -- Leave at 0. Cooldown will be handled after the discombob explodes.
SWEP.PostDetCooldown = 1.5 -- Unique param for the discombob; applies after the previous nade explodes.

SWEP.CFC_FirstTimeHints = {
    {
        Message = "The Discombob deals no damage, but pushes people around.",
        Sound = "ambient/water/drip1.wav",
        Duration = 10,
        DelayNext = 6,
    },
    {
        Message = "Attack again or reload after throwing the Discombob to detonate it early.",
        Sound = "ambient/water/drip2.wav",
        Duration = 7,
        DelayNext = 0,
    },
}


function SWEP:SetupDataTables()
    BaseClass.SetupDataTables( self )

    self:AddNetworkVar( "Bool", "WaitingForNadeDet" )
end

function SWEP:Initialize()
    BaseClass.Initialize( self )
    self:SetMaterial( "models/weapons/w_models/cfc_frag_grenade/frag_grenade_discombob" )
end

function SWEP:CanThrow()
    if self:GetWaitingForNadeDet() then return false end

    return BaseClass.CanThrow( self )
end

function SWEP:Throw()
    BaseClass.Throw( self )

    self:SetFinishReload( CurTime() + 999 ) -- Put the reload anim on indefinite hold.

    if CLIENT then
        self._discombobPlayedManualDetSound = nil
    end
end

function SWEP:Reload()
    self:TryManualDetonation()
end

function SWEP:PrimaryAttack()
    self:TryManualDetonation()

    return BaseClass.PrimaryAttack( self )
end

function SWEP:SecondaryAttack()
    self:TryManualDetonation()

    return BaseClass.SecondaryAttack( self )
end

function SWEP:TryManualDetonation()
    if not self:GetWaitingForNadeDet() then return end

    local playDetSound = false

    if SERVER then
        local nade = self._discombobNadeEnt

        if IsValid( nade ) then
            playDetSound = true
            self._discombobNadeEnt = nil
            nade:Explode()
        end
    elseif not self._discombobPlayedManualDetSound then
        playDetSound = true
        self._discombobPlayedManualDetSound = true
    end

    if playDetSound then
        self:EmitSound( "weapons/slam/buttonclick.wav" )
    end
end


if SERVER then
    function SWEP:CreateEntity()
        local ent = ents.Create( "cfc_simple_ent_discombob" )
        local ply = self:GetOwner()

        ent:SetPos( ply:GetPos() )
        ent:SetAngles( ply:EyeAngles() )
        ent:SetOwner( ply )
        ent:Spawn()
        ent:Activate()

        ent:SetTimer( 3 )

        local radiusMult = self.Primary.RadiusMult
        local strengthMult = self.Primary.StrengthMult
        local strengthMultSelf = self.Primary.StrengthMultSelf

        ent.Radius = ent.Radius * radiusMult
        ent.Knockback = ent.Knockback * strengthMult
        ent.PlayerKnockback = ent.PlayerKnockback * strengthMult
        ent.PlayerSelfKnockback = ent.PlayerSelfKnockback * strengthMultSelf

        self:SetWaitingForNadeDet( true )
        self._discombobNadeEnt = ent

        local selfObj = self

        ent:CallOnRemove( "CFC_PvPWeapons_Discombob_TrackDetonation", function()
            if not IsValid( selfObj ) then return end

            local reloadAnimDur = selfObj:GetTranslatedWeaponAnimDuration( ACT_VM_DRAW )
            local timeUntilReady = math.max( selfObj.PostDetCooldown, reloadAnimDur )
            local timeUntilReloadStart = timeUntilReady - reloadAnimDur

            selfObj._discombobNadeEnt = nil
            selfObj:SetFinishReload( CurTime() + timeUntilReloadStart ) -- Delay the reload anim based on post-det cooldown.

            timer.Create( "CFC_PvPWeapons_Discombob_Cooldown" .. selfObj:EntIndex(), selfObj.PostDetCooldown, 1, function()
                if not IsValid( selfObj ) then return end

                selfObj:SetWaitingForNadeDet( false )
            end )
        end )

        return ent
    end
end
