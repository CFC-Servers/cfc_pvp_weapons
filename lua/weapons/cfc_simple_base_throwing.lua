AddCSLuaFile()

SWEP.Base = "weapon_base"

SWEP.m_WeaponDeploySpeed = 1

SWEP.DrawWeaponInfoBox = false

SWEP.ViewModelFOV = 54

SWEP.CFCSimpleWeapon = true
SWEP.CFCSimpleWeaponThrowing = true

SWEP.ThrowVelMul = 1
SWEP.ProjectileClass = ""
SWEP.InfiniteAmmo = nil
SWEP.IdleHoldType = "normal"
SWEP.ThrowingHoldType = "melee"

SWEP.ModelScale = 1
SWEP.ModelMaterial = nil

SWEP.WorldModel = "models/weapons/w_grenade.mdl"
SWEP.WMPosOffset = Vector( 0, 0, 0 )
SWEP.WMAngOffset = Angle( 0, 0, 0 )

SWEP.HeldModel = nil
SWEP.HeldModelPosOffset = Vector( 0, 0, 0 )
SWEP.HeldModelAngOffset = Angle( 0, 0, 0 )

SWEP.Primary.Ammo = ""
SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = false

SWEP.Primary.ThrowAct = { ACT_VM_PULLBACK_HIGH, ACT_VM_THROW }
SWEP.Primary.LobAct = { ACT_VM_PULLBACK_LOW, ACT_VM_HAULBACK }
SWEP.Primary.RollAct = { ACT_VM_PULLBACK_LOW, ACT_VM_SECONDARYATTACK }

SWEP.Secondary.Ammo = ""
SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = 0
SWEP.Secondary.Automatic = false

function SWEP:SetupDataTables()
    self._NetworkVars = {
        ["String"] = 0,
        ["Bool"]   = 0,
        ["Float"]  = 0,
        ["Int"]    = 0,
        ["Vector"] = 0,
        ["Angle"]  = 0,
        ["Entity"] = 0
    }

    self:AddNetworkVar( "Int", "ThrowMode" )

    self:AddNetworkVar( "Float", "NextIdle" )
    self:AddNetworkVar( "Float", "FinishThrow" )
    self:AddNetworkVar( "Float", "FinishReload" )

end

function SWEP:Initialize()
    self:SetHoldType( self.IdleHoldType )
    self:SetNW2Bool( "ThrowableInHand", true )
    if self.ModelMaterial then
        self:SetMaterial( self.ModelMaterial )
    end
    if CLIENT and self.HeldModel then
        self.MyHeldModel = ClientsideModel( self.HeldModel )
        self.MyHeldModel:SetMaterial( self.ModelMaterial )
        self.MyHeldModel:SetNoDraw( true )
        self.MyHeldModel:SetParent( self )
    end
end

function SWEP:AddNetworkVar( varType, name, extended )
    local index = assert( self._NetworkVars[varType], "Attempt to register unknown network var type " .. varType )
    local max = varType == "String" and 3 or 31

    if index >= max then
        error( "Network var limit exceeded for " .. varType )
    end

    self:NetworkVar( varType, index, name, extended )
    self._NetworkVars[varType] = index + 1
end

function SWEP:Deploy()
    self:SetNextIdle( CurTime() + self:SendTranslatedWeaponAnim( ACT_VM_DRAW ) )

    return true
end

function SWEP:Holster()
    if CLIENT and IsFirstTimePredicted() then
        self:TearDownViewModel()

    end
    return true
end

function SWEP:CanThrow()
    if self:GetFinishThrow() > 0 then
        return false
    end

    if self:GetFinishReload() > 0 then
        return false
    end

    return true
end

function SWEP:EmitThrowSound()
    self:EmitSound( "WeaponFrag.Throw" )
end

function SWEP:PrimaryAttack()
    if not self:CanThrow() then
        return
    end

    self:SetHoldType( self.ThrowingHoldType )

    self:SetThrowMode( 1 )
    self:SetFinishThrow( CurTime() + self:SendTranslatedWeaponAnim( self.Primary.ThrowAct[1] ) )
    self:SetNextIdle( 0 )

end

function SWEP:SecondaryAttack()
    if not self:CanThrow() then
        return
    end

    local duration = 0
    self:SetHoldType( self.ThrowingHoldType )

    if self:GetOwner():Crouching() then
        duration = self:SendTranslatedWeaponAnim( self.Primary.RollAct[1] )
        self:SetThrowMode( 3 )
    else
        duration = self:SendTranslatedWeaponAnim( self.Primary.LobAct[1] )
        self:SetThrowMode( 2 )
    end

    self:SetFinishThrow( CurTime() + duration )
    self:SetNextIdle( 0 )

end

function SWEP:Throw()
    local ply = self:GetOwner()

    ply:SetAnimation( PLAYER_ATTACK1 )

    self:EmitThrowSound()

    local mode = self:GetThrowMode()

    if SERVER then
        self:ThrowEntity( mode )
    end

    local act

    if mode == 1 then
        act = self.Primary.ThrowAct[2]
    elseif mode == 2 then
        act = self.Primary.LobAct[2]
    elseif mode == 3 then
        act = self.Primary.RollAct[2]
    end

    self:SetFinishReload( CurTime() + self:SendTranslatedWeaponAnim( act ) )
    self:TakePrimaryAmmo( 1 )
end

if SERVER then
    function SWEP:GetThrowPosition( pos )
        local ply = self:GetOwner()
        local tr = util.TraceHull( {
            start = ply:EyePos(),
            endpos = pos,
            mins = Vector( -4, -4, -4 ),
            maxs = Vector( 4, 4, 4 ),
            filter = ply
        } )

        return tr.Hit and tr.HitPos or pos
    end

    function SWEP:CreateEntity()
    end

    function SWEP:ThrowEntity( mode )
        local ply = self:GetOwner()
        local ent = self:CreateEntity()

        if not IsValid( ent ) then
            return
        end

        ent:SetOwner( ply )
        timer.Simple( 0.25, function()
            if not IsValid( ent ) then return end
            ent:SetOwner()

        end )

        self:SetNW2Bool( "ThrowableInHand", false )

        if self.ModelMaterial then
            ent:SetMaterial( self.ModelMaterial )

        end

        local moveType = ent:GetMoveType()
        local phys = ent:GetPhysicsObject()

        ent:SetAngles( AngleRand() )

        if mode == 1 then
            local pos = LocalToWorld( Vector( 18, -8, 0 ), angle_zero, ply:GetShootPos(), ply:GetAimVector():Angle() )

            ent:SetPos( self:GetThrowPosition( pos ) )

            local vel = ply:GetVelocity() + ( ply:GetForward() + Vector( 0, 0, 0.05 ) ) * 1200 * self.ThrowVelMul
            local angVel = Vector( 600, math.random( -1200, 1200 ), 0 )

            self:DoVel( phys, ent, moveType, vel, angVel )

        elseif mode == 3 then
            local pos = ply:GetPos() + Vector( 0, 0, 4 )
            local facing = ply:GetAimVector()

            facing.z = 0
            facing = facing:GetNormalized()

            local tr = util.TraceLine( {
                start = pos,
                endpos = pos + Vector( 0, 0, -16 ),
                filter = ply
            } )

            if tr.Fraction ~= 1 then
                local tan = facing:Cross( tr.Normal )

                facing = tr.Normal:Cross( tan )
            end

            pos = pos + ( facing * 18 )

            ent:SetPos( self:GetThrowPosition( pos ) )
            ent:SetAngles( Angle( 0, ply:GetAngles().y, -90 ) )

            local vel = ply:GetVelocity() + ply:GetForward() * 700 * self.ThrowVelMul
            local angVel = Vector( 0, 0, 720 )

            self:DoVel( phys, ent,  moveType, vel, angVel )

        elseif mode == 2 then
            local pos = LocalToWorld( Vector( 18, -8, 0 ), angle_zero, ply:GetShootPos(), ply:GetAimVector():Angle() )

            ent:SetPos( self:GetThrowPosition( pos ) )

            local vel = ply:GetVelocity() + ( ply:GetForward() * 350 * self.ThrowVelMul ) + Vector( 0, 0, 50 )
            local angVel = Vector( 200, math.random( -600, 600 ), 0 )

            self:DoVel( phys, ent,  moveType, vel, angVel )
        end
    end

    function SWEP:DoVel( phys, ent, moveType, vel, angVel )
        if IsValid( phys ) and moveType ~= MOVETYPE_FLYGRAVITY then
            phys:SetVelocity( vel )
            phys:AddAngleVelocity( angVel )
        else
            ent:SetVelocity( vel )
            ent:SetLocalAngularVelocity( angVel:Angle() )
        end
    end
end

function SWEP:TranslateWeaponAnim( act )
    return act
end

function SWEP:SendTranslatedWeaponAnim( act )
    act = self:TranslateWeaponAnim( act )

    if not act then
        return
    end

    self:SendWeaponAnim( act )

    return self:SequenceDuration( self:SelectWeightedSequence( act ) )
end

function SWEP:FinishReload()
    local ply = self:GetOwner()

    if not self.InfiniteAmmo and ply:GetAmmoCount( self.Primary.Ammo ) <= 0 then
        if SERVER then
            ply:StripWeapon( self.ClassName )
        end

        return false
    end

    local time = CurTime() + self:SendTranslatedWeaponAnim( ACT_VM_DRAW )

    self:SetNextIdle( time )

    self:SetNW2Bool( "ThrowableInHand", true )

    self:SetNextPrimaryFire( time )
    self:SetNextSecondaryFire( time )
    self:SetHoldType( self.IdleHoldType )

    return true
end

function SWEP:Think()
    local owner = self:GetOwner()
    local idle = self:GetNextIdle()

    if idle > 0 and idle <= CurTime() then
        self:SendTranslatedWeaponAnim( ACT_VM_IDLE )

        self:SetNextIdle( 0 )
    end

    local reload = self:GetFinishReload()

    if reload > 0 and reload <= CurTime() then
        self:FinishReload()

        self:SetFinishReload( 0 )
    end

    local throw = self:GetFinishThrow()

    if throw > 0 and throw <= CurTime() and not owner:KeyDown( self:GetThrowMode() == 1 and IN_ATTACK or IN_ATTACK2 ) then
        self:Throw()

        self:SetFinishThrow( 0 )
    end

    self.oldOwner = owner
    if CLIENT then
        self:SetupViewModel()

    end
end

function SWEP:OnReloaded()
    self:SetWeaponHoldType( self:GetHoldType() )
end

function SWEP:OnRestore()
    self:SetNextIdle( CurTime() )
    self:SetFinishThrow( 0 )
    self:SetFinishReload( 0 )
end

function SWEP:OnDrop()
end


if not CLIENT then return end

function SWEP:DoDrawCrosshair( _x, _y )
    return self:GetFinishThrow() == 0
end

function SWEP:CustomAmmoDisplay()
    return {
        Draw = true,
        PrimaryClip = self:GetOwner():GetAmmoCount( self.Primary.Ammo )
    }
end

-- hack, but it works!
function SWEP:OwnerChanged()
    if IsValid( self.oldOwner ) then
        self:TearDownViewModel( self.oldOwner )
        self.oldOwner = nil
    end
end

function SWEP:DrawWorldModel()
    local owner = self:GetOwner()
    if IsValid( owner ) then
        local attachId = owner:LookupAttachment( "anim_attachment_RH" )
        if attachId <= 0 then return end
        local attachTbl = owner:GetAttachment( attachId )
        local posOffsetW, angOffsetW = LocalToWorld( self.WMPosOffset, self.WMAngOffset, attachTbl.Pos, attachTbl.Ang )
        self:SetPos( posOffsetW )
        self:SetAngles( angOffsetW )

    end
    if not self:GetNW2Bool( "ThrowableInHand" ) then return end
    self:SetModelScale( self.ModelScale )
    self:DrawModel()
end

function SWEP:SetupViewModel()
    if not self.HeldModel then return end

    if not self.ViewModelSetup then
        local vm = self:GetOwner():GetViewModel( 0 )
        vm:SetupBones()

        local nadeBone = vm:LookupBone( "ValveBiped.Grenade_body" )
        if not nadeBone then return end -- just in case someone has a really screwed up custom model

        self.MyHeldModel:FollowBone( vm, nadeBone )
        local bonePos, boneAng = vm:GetBonePosition( nadeBone )
        local offsettedPos, offsettedAng = LocalToWorld( self.HeldModelPosOffset, self.HeldModelAngOffset, bonePos, boneAng )
        self.MyHeldModel:SetPos( offsettedPos )
        self.MyHeldModel:SetAngles( offsettedAng )

        self.MyHeldModel:SetModelScale( self.ModelScale )

        self:CallOnRemove( "remove_extramodel", function( me ) me:TearDownViewModel() end, me )
        self.ViewModelSetup = true
    end
end

function SWEP:TearDownViewModel( owner )
    owner = owner or self:GetOwner()
    if not IsValid( owner ) then return end
    self.ViewModelSetup = nil
    self.MyHeldModel:SetParent( self )

end

local invisMat = Material( "models/blackout/blackout" )

function SWEP:PreDrawViewModel()
    if not self.ViewModelSetup then
        self:SetupViewModel()
        return

    end
    self.MyHeldModel:DrawModel()

    render.MaterialOverrideByIndex( 0, invisMat )
    render.MaterialOverrideByIndex( 1, invisMat )
    render.MaterialOverrideByIndex( 2, invisMat )
    render.MaterialOverrideByIndex( 3, invisMat )
    render.MaterialOverrideByIndex( 4, invisMat )

end