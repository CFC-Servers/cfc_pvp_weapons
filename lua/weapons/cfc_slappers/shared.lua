if SERVER then
    AddCSLuaFile( "shared.lua" )
    resource.AddFile( "materials/models/weapons/v_arms.vmt" )
    resource.AddFile( "materials/models/weapons/watch.vmt" )

    for i = 1, 9 do
        resource.AddFile( string.format( "sound/elevator/effects/slap_hit0%s.wav", i ) )
    end

    CreateConVar( "slappers_slap_weapons_consecutive", 8, FCVAR_REPLICATED, "Consecutive hits required to slap weapons" )
    CreateConVar( "slappers_slap_weapons", 1, FCVAR_REPLICATED, "Slap weapons out of players' hands" )
    CreateConVar( "slappers_force", 180, FCVAR_REPLICATED, "Force of the slappers" )
    util.AddNetworkString( "SlapAnimation" )
end

SWEP.Spawnable = true
SWEP.AdminSpawnable = true
SWEP.PrintName = "Slappers"
SWEP.Purpose = "Slap"
SWEP.Category = "CFC"
SWEP.Slot = 1
SWEP.SlotPos = 0
SWEP.ViewModel = Model( "models/weapons/v_watch.mdl" )
SWEP.WorldModel = ""
SWEP.HoldType = "normal"

SWEP.Primary = {
    ClipSize = -1,
    Delay = 0.4,
    DefaultClip = -1,
    Automatic = false,
    Ammo = "none"
}

SWEP.Secondary = SWEP.Primary

SWEP.Sounds = {
    LoseWeapon = Sound( "npc/zombie/zombie_pound_door.wav" ),
    Miss = Sound( "Weapon_Knife.Slash" ),
    HitWorld = {
        Sound( "Flesh.ImpactHard" ),
        Sound( "d1_canals.citizenpunch_pain_1" )
    },
    Hurt = {
        Sound( "npc_citizen.pain01" ),
        Sound( "npc_citizen.pain05" )
    },
    Slap = {
        Sound( "elevator/effects/slap_hit01.wav" ),
        Sound( "elevator/effects/slap_hit02.wav" ),
        Sound( "elevator/effects/slap_hit03.wav" ),
        Sound( "elevator/effects/slap_hit04.wav" ),
        Sound( "elevator/effects/slap_hit05.wav" ),
        Sound( "elevator/effects/slap_hit06.wav" ),
        Sound( "elevator/effects/slap_hit07.wav" ),
        Sound( "elevator/effects/slap_hit08.wav" ),
        Sound( "elevator/effects/slap_hit09.wav" )
    }
}

SWEP.NPCFilter = { "npc_monk", "npc_alyx", "npc_barney", "npc_citizen", "npc_kleiner", "npc_magnusson", "npc_eli", "npc_fisherman", "npc_gman", "npc_mossman", "npc_odessa", "npc_breen" }

SWEP.Mins = Vector( -8, -8, -8 )
SWEP.Maxs = Vector( 8, 8, 8 )

--[[
	Weapon Config
]]
function SWEP:Initialize()
    self:SetWeaponHoldType( self.HoldType )
    self:DrawShadow( false )

    if CLIENT then
        self:SetupHands()
    end
end

function SWEP:CanPrimaryAttack()
    return true
end

function SWEP:CanSecondaryAttack()
    return true
end

function SWEP:ShouldDropOnDie()
    return false
end

--[[
	Slap Animation Reset
]]
if SERVER then
    function SWEP:Think()
        local vm = self:GetOwner():GetViewModel()

        if self:GetNextPrimaryFire() < CurTime() and vm:GetSequence() ~= 0 then
            vm:ResetSequence( 0 )
        end
    end
end

if CLIENT then
    local CvarAnimCam = CreateClientConVar( "slappers_animated_camera", 0, true, false )
    SWEP.DrawCrosshair = false

    function SWEP:DrawHUD()
    end

    function SWEP:DrawWorldModel()
    end

    local function GetViewModelAttachment( attachment )
        local vm = LocalPlayer():GetViewModel()
        local attachID = vm:LookupAttachment( attachment )

        return vm:GetAttachment( attachID )
    end

    --[[-----------------------------------------
		CalcView override effect
		
		Uses attachment angles on view
		model for view angles
	-------------------------------------------]]
    function SWEP:CalcView( _, origin, angles, fov )
        -- don't alter calcview when in vehicle
        if CvarAnimCam:GetBool() and not IsValid( self:GetOwner():GetVehicle() ) then
            local attach = GetViewModelAttachment( "attach_camera" )

            if attach and self:GetNextPrimaryFire() > CurTime() then
                local angdiff = angles - ( attach.Ang + Angle( 0, 0, -90 ) )

                -- SUPER HACK
                -- view is flipped
                if self:GetNextPrimaryFire() > CurTime() and angdiff.r > 179.9 then
                    angdiff.p = -( 89 - angles.p ) -- find pitch difference to stop at 89 degrees
                end

                angles = angles - angdiff
            end
        end

        return origin, angles, fov
    end

    --[[-----------------------------------------
		Allow slappers to use hand view model
	-----------------------------------------]]
    local CvarUseHands = CreateClientConVar( "slappers_vm_hands", 1, true, false )
    local shouldHideVM = false

    function SWEP:PreDrawViewModel( vm )
        if shouldHideVM then
            shouldHideVM = false
            vm:SetMaterial( "engine/occlusionproxy" )
        end
    end

    local viewOffs = Vector( -0.2,0,-1.65 )
    function SWEP:GetViewModelPosition( pos, ang )
        return pos + viewOffs,ang
    end

    function SWEP:SetupHands()
        local useHands = CvarUseHands:GetBool()
        self.UseHands = useHands
        shouldHideVM = useHands
    end

    function SWEP:Holster()
        self:OnRemove()

        return true
    end

    function SWEP:OnRemove()
        if not IsValid( self:GetOwner() ) then return end
        local vm = self:GetOwner():GetViewModel()

        if IsValid( vm ) then
            vm:SetMaterial( "" )
        end
    end
end

--[[
	Weapon Slapping
]]
function SWEP:SlapWeaponOutOfHands( ent )
    if not GetConVar( "slappers_slap_weapons" ):GetBool() then return end
    local weapon = ent:GetActiveWeapon()
    if not IsValid( weapon ) then return end
    local class = weapon:GetClass()
    if class == "slappers" then return end
    if class == "weapon_fists" then return end
    local pos = weapon:GetPos()

    local consecutives = weapon.ConsecutiveSlaps or 0
    weapon.ConsecutiveSlaps = consecutives + 1

    timer.Simple( 2, function()
        if not IsValid( weapon ) then return end
        local oldSlaps = weapon.ConsecutiveSlaps
        if not oldSlaps then return end
        newSlaps = oldSlaps + -1
        if newSlaps <= 0 then weapon.ConsecutiveSlaps = nil return end
        weapon.ConsecutiveSlaps = newSlaps
    end )


    local entMaxHealth = ent:GetMaxHealth()
    local multiplier = entMaxHealth / 100
    local consecutiveQuotaAdjusted = GetConVar( "slappers_slap_weapons_consecutive" ):GetInt() * multiplier

    if weapon.ConsecutiveSlaps < consecutiveQuotaAdjusted then return end

    ent:EmitSound( self.Sounds.LoseWeapon, 80, 150, 1, CHAN_STATIC )

    -- Strip them of their weapon
    if ent:IsPlayer() then
        ent:StripWeapon( class )
    elseif ent:IsNPC() then
        weapon:Remove()
    end

    -- Spawn a new physical one
    local wep = ents.Create( class )
    local hand = ent:LookupBone( "ValveBiped.Bip01_R_Hand" )

    if hand then
        pos = ent:GetBonePosition( hand )
    else
        pos = ent:GetPos()
    end

    wep:SetPos( pos )
    wep:SetOwner( ent )
    wep:Spawn()
    wep.SlapperCannotPickup = CurTime() + 3
    local phys = wep:GetPhysicsObject()

    if IsValid( phys ) then
        timer.Simple( 0.01, function()
            local ang = self:GetOwner():EyeAngles()
            phys:ApplyForceCenter( ang:Forward() * 3000 + ang:Right() * 3000 + Vector( 0, 0, math.Rand( 1500, 3000 ) ) )
        end )
    end
end

hook.Add( "PlayerCanPickupWeapon", "SlapCanPickup", function( _, weapon )
    if weapon.SlapperCannotPickup and weapon.SlapperCannotPickup > CurTime() then return false end
end )

function SWEP:SlapPlayer( ply, tr )

    local myUser = self:GetOwner()
    local toSlap = ply
    if hook.Run( "slappers_weapon_can_slap_otherplayer", myUser, toSlap ) == false then return end

    -- Apply force to player
    local origVel = ply:GetVelocity()
    local vec = ( tr.HitPos - tr.StartPos ):GetNormal()
    local mul = GetConVar( "slappers_force" ):GetInt()
    local slapVel = vec * mul
    slapVel.z = math.Clamp( slapVel.z, 75, math.huge )
    local vel = slapVel + origVel
    ply:SetLocalVelocity( vel )

    -- Slap current weapon out of player's hands
    self:SlapWeaponOutOfHands( ply )

    -- Emit slap sound
    self:GetOwner():EmitSound( table.Random( self.Sounds.Slap ), 80, math.random( 92, 108 ), 1, CHAN_STATIC )
    -- Emit hurt sound on player
    ply:EmitSound( table.Random( self.Sounds.Hurt ), 50, math.random( 92, 108 ) )

    local oldPunchAng = ply:GetViewPunchAngles()
    local punchAng = oldPunchAng + Angle( -3, 2, 0 )
    ply:ViewPunch( punchAng )

end

function SWEP:SlapNPC( ent, tr )
    local vec = ( tr.HitPos - tr.StartPos ):GetNormal()
    -- Apply slap velocity to NPC
    if ent.GetPhysicsObject then
        local obj = ent:GetPhysicsObject()
        if obj:IsValid() then
            local force = math.Clamp( GetConVar( "slappers_force" ):GetInt() - obj:GetMass(), 0, math.huge )
            local vel = vec * force * 4.75
            vel.z = math.Clamp( vel.z, 50, 500 )
            ent:SetLocalVelocity( vel )
        end
    end

    -- Filter entities that respond to slaps
    if table.HasValue( self.NPCFilter, ent:GetClass() ) then
        ent:EmitSound( table.Random( self.Sounds.Hurt ), 50, math.random( 95, 105 ) )
    end

    -- Only hurt non-friendly NPCs
    if ent:Disposition( self:GetOwner() ) ~= D_LI then
        -- Damage potential enemies
        local dmginfo = DamageInfo()
        dmginfo:SetDamagePosition( tr.HitPos )
        dmginfo:SetDamageType( DMG_CLUB )
        dmginfo:SetAttacker( self:GetOwner() )
        dmginfo:SetInflictor( self:GetOwner() )
        dmginfo:SetDamage( math.random( 4, 6 ) )
        ent:TakeDamageInfo( dmginfo )
    end

    -- Slap current weapon out of NPC's hands
    self:SlapWeaponOutOfHands( ent )

    -- Emit slap sound
    self:GetOwner():EmitSound( table.Random( self.Sounds.Slap ), 80, math.random( 92, 108 ) )
end

function SWEP:SlapWorld( _, tr )
    self:GetOwner():EmitSound( table.Random( self.Sounds.HitWorld ), 80, math.random( 92, 108 ) )
    self:GetOwner():EmitSound( table.Random( self.Sounds.Slap ), 80, math.random( 92, 108 ) )
    -- i just slapped a wall! that oughta hurt!
    local damage = math.random( 1, 2 )
    local dmginfo = DamageInfo()
    dmginfo:SetDamageType( DMG_CLUB )
    dmginfo:SetAttacker( self:GetOwner() )
    dmginfo:SetInflictor( game.GetWorld() )
    dmginfo:SetDamage( damage )
    self:GetOwner():TakeDamageInfo( dmginfo )

    -- Apply force to self
    local origVel = self:GetOwner():GetVelocity()
    local vec = ( tr.HitPos - tr.StartPos ):GetNormal()
    local mul = GetConVar( "slappers_force" ):GetInt()
    local slapVel = -vec * mul
    local vel = slapVel * 0.6 + origVel --
    self:GetOwner():SetLocalVelocity( vel )

end

function SWEP:SlapProp( ent, tr )
    local vec = ( tr.HitPos - tr.StartPos ):GetNormal()
    local emitSound = self.Sounds.HitWorld
    local damage = math.random( 4, 6 )

    if ent:GetClass() == "func_button" then
        ent:Use( self:GetOwner(), self:GetOwner() ) -- Press button
    elseif string.match( ent:GetClass(), "door" ) then
        ent:Use( self:GetOwner(), self:GetOwner() ) -- Open door
    elseif ent:Health() > 0 then
        if ent:Health() <= damage then
            ent:Fire( "Break" )
        else
            -- Damage props with health
            local dmginfo = DamageInfo()
            dmginfo:SetDamagePosition( tr.HitPos )
            dmginfo:SetDamageType( DMG_CLUB )
            dmginfo:SetAttacker( self:GetOwner() )
            dmginfo:SetInflictor( self:GetOwner() )
            dmginfo:SetDamage( damage )
            ent:TakeDamageInfo( dmginfo )
        end
    end

    -- Apply force to prop
    local phys = ent:GetPhysicsObject()

    if IsValid( phys ) then
        emitSound = table.Random( self.Sounds.Slap )
        phys:SetVelocity( phys:GetVelocity() + vec * GetConVar( "slappers_force" ):GetInt() * math.Clamp( 100 / phys:GetMass(), 0, 1 ) )
    end

    -- Emit slap sound
    self:GetOwner():EmitSound( emitSound, 80, math.random( 92, 108 ) )
end

--[[
	Third Person Slap Hack
]]
function SWEP:SlapAnimation()
    -- Inform players of slap
    if SERVER and not game.SinglePlayer() then
        net.Start( "SlapAnimation" )
        net.WriteEntity( self:GetOwner() )
        net.Broadcast()
    end

    -- Temporarily change hold type so that we
    -- can use the crowbar melee animation
    self:SetWeaponHoldType( "melee" )
    self:GetOwner():SetAnimation( PLAYER_ATTACK1 )

    -- Change back to normal holdtype once we're done
    timer.Simple( 0.3, function()
        if IsValid( self ) then
            self:SetWeaponHoldType( self.HoldType )
        end
    end )
end

net.Receive( "SlapAnimation", function()
    -- Make sure the player is still valid
    local ply = net.ReadEntity()
    if not IsValid( ply ) then return end
    -- Make sure they're still using the slappers
    local weapon = ply:GetActiveWeapon()
    if not IsValid( weapon ) or not weapon.SlapAnimation then return end
    -- Perform slap animation
    weapon:SlapAnimation()
end )

function SWEP:Slap()
    -- Broadcast third person slap
    self:SlapAnimation()

    -- Perform trace
    if SERVER then
        -- Use view model slap animation
        self:SendWeaponAnim( ACT_VM_PRIMARYATTACK_2 )

        local punchScale = 1

        -- Trace for slap hit
        local tr = util.TraceHull( {
            start = self:GetOwner():GetShootPos(),
            endpos = self:GetOwner():GetShootPos() + self:GetOwner():GetAimVector() * 54,
            mins = self.Mins,
            maxs = self.Maxs,
            filter = self:GetOwner()
        } )

        local ent = tr.Entity

        if IsValid( ent ) or game.GetWorld() == ent then
            if ent:IsPlayer() then
                self:SlapPlayer( ent, tr )
            elseif ent:IsNPC() then
                self:SlapNPC( ent, tr )
            elseif ent:IsWorld() then
                self:SlapWorld( ent, tr )
            else
                self:SlapProp( ent, tr )
            end
        else
            self:GetOwner():EmitSound( self.Sounds.Miss, 80, math.random( 92, 108 ) )
            punchScale = 0.1
        end

        local side = -4
        if self.ViewModelFlip then
            side = -side
        end

        local oldPunchAng = self:GetOwner():GetViewPunchAngles()
        local punchAng = oldPunchAng + Angle( -6, side, 0 ) * punchScale
        self:GetOwner():ViewPunch( punchAng )

    end
end

--[[
	Slapping
]]
function SWEP:PrimaryAttack()
    if game.SinglePlayer() then
        self:CallOnClient( "PrimaryAttack", "" )
    end

    -- Left handed slap
    self.ViewModelFlip = false
    self:Slap()
    self:SetNextPrimaryFire( CurTime() + self.Primary.Delay )
end

function SWEP:SecondaryAttack()
    if game.SinglePlayer() then
        self:CallOnClient( "SecondaryAttack", "" )
    end

    -- Right handed slap
    self.ViewModelFlip = true
    self:Slap()
    self:SetNextSecondaryFire( CurTime() + self.Primary.Delay )
end
