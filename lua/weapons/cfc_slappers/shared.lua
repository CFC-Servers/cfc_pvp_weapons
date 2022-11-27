if SERVER then
    AddCSLuaFile( "shared.lua" )
    resource.AddFile( "materials/models/weapons/v_arms.vmt" )
    resource.AddFile( "materials/models/weapons/watch.vmt" )

    for i = 1, 9 do
        resource.AddFile( string.format( "sound/elevator/effects/slap_hit0%s.wav", i ) )
    end

    CreateConVar( "slappers_slap_weapons_consecutive", 8, FCVAR_ARCHIVE, "Consecutive hits required to slap weapons" )
    CreateConVar( "slappers_slap_weapons", 1, FCVAR_ARCHIVE, "Slap weapons out of players' hands" )
    CreateConVar( "slappers_base_force", 180, FCVAR_ARCHIVE, "Base force of the slappers" )
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

SWEP.NPCFilter = {
    npc_eli = true,
    npc_alyx = true,
    npc_gman = true,
    npc_monk = true,
    npc_breen = true,
    npc_barney = true,
    npc_odessa = true,
    npc_citizen = true,
    npc_kleiner = true,
    npc_mossman = true,
    npc_fisherman = true,
    npc_magnusson = true,
}

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
    Base stuff
]]
function SWEP:ForceMul()
    return 1
end

function SWEP:WeaponKnockWeight()
    return 1
end

function SWEP:Pitch( pitch )
    return pitch
end

function SWEP:Level( level )
    return level
end

function SWEP:SlapSound()
    self:GetOwner():EmitSound( table.Random( self.Sounds.Slap ), self:Level( 80 ), self:Pitch( math.random( 92, 108 ) ), 1, CHAN_STATIC )
end

function SWEP:ViewPunchSlapper( ent, punchAng )
    ent:ViewPunch( punchAng )
end

--[[
	Slap Animation Reset
]]
if SERVER then
    function SWEP:Think()
        local owner = self:GetOwner()
        if not IsValid( owner ) then return end

        local vm = owner:GetViewModel()

        local nextFire = nil
        if self.PrimaryAttacking then
            nextFire = self:GetNextPrimaryFire()
        else
            nextFire = self:GetNextSecondaryFire()
        end
        if nextFire < CurTime() and vm:GetSequence() ~= 0 then
            vm:ResetSequence( 0 )

        end
    end
end

if CLIENT then
    SWEP.DrawCrosshair = false

    function SWEP:DrawHUD()
    end

    function SWEP:DrawWorldModel()
    end

    --[[-----------------------------------------
		Allow slappers to use hand view model
	-----------------------------------------]]
    local CvarUseHands = CreateClientConVar( "slappers_vm_hands", 1, true, false )
    local shouldHideVM = false

    function SWEP:PreDrawViewModel( vm )
        if not shouldHideVM then return end
        shouldHideVM = false
        vm:SetMaterial( "engine/occlusionproxy" )
    end

    local viewOffs = Vector( -0.2, 0, -1.65 )
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
        local owner = self:GetOwner()
        if not IsValid( owner ) then return end

        local vm = owner:GetViewModel()
        if not IsValid( vm ) then return end

        vm:SetMaterial( "" )
    end
end

--[[
	Weapon Slapping
]]

local buildupTimeout = 2

function SWEP:SlapWeaponOutOfHands( ent )
    if not GetConVar( "slappers_slap_weapons" ):GetBool() then return end

    local weapon = ent:GetActiveWeapon()
    if not IsValid( weapon ) then return end

    local class = weapon:GetClass()
    if class == "slappers" then return end
    if class == "weapon_fists" then return end

    local pos = weapon:GetPos()

    weapon.ConsecutiveSlaps = ( weapon.ConsecutiveSlaps or 0 ) + self:WeaponKnockWeight()

    timer.Simple( buildupTimeout, function()
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

    ent:EmitSound( self.Sounds.LoseWeapon, self:Level( 80 ), self:Pitch( 150 ), 1, CHAN_STATIC )

    -- Strip them of their weapon
    if ent:IsPlayer() then
        ent:StripWeapon( class )
    elseif ent:IsNPC() then
        weapon:Remove()
    end

    -- Spawn a new physical one
    local wep = ents.Create( class )
    local hand = ent:LookupBone( "ValveBiped.Bip01_R_Hand" )

    pos = hand and ent:GetBonePosition( hand ) or ent:GetPos()

    wep:SetPos( pos )
    wep:SetOwner( ent )
    wep:Spawn()
    wep.SlapperCannotPickup = CurTime() + 3
    local phys = wep:GetPhysicsObject()

    if IsValid( phys ) then
        timer.Simple( 0.01, function()
            local ang = self:GetOwner():EyeAngles()

            local relative = ang:Forward() * 3000 + ang:Right() * 3000
            local alwaysUp = ang:Forward() * 3000 + ang:Right() * 3000 + Vector( 0, 0, math.Rand( 1500, 3000 ) )
            local force = relative + alwaysUp
            local forceMultiplied = force * self:ForceMul()

            phys:ApplyForceCenter( forceMultiplied )

        end )
    end
end

hook.Add( "PlayerCanPickupWeapon", "SlapCanPickup", function( _, weapon )
    local timeout = weapon.SlapperCannotPickup
    if not timeout then return end

    if timeout > CurTime() then return false end
end )

function SWEP:SlapPlayer( ply, tr )
    local myUser = self:GetOwner()
    local toSlap = ply
    if hook.Run( "slappers_weapon_can_slap_otherplayer", myUser, toSlap ) == false then return end

    local origVel = ply:GetVelocity()

    -- Apply force to player
    local vec = ( tr.HitPos - tr.StartPos ):GetNormal()
    local mul = GetConVar( "slappers_base_force" ):GetInt()
    local slapVel = vec * mul

    -- make sure this doesn't get out of hand
    slapVel.z = math.max( slapVel.z, 75 )
    -- account for the weapon specific mul
    local slapVelMultipled = slapVel * self:ForceMul()
    -- add these up!
    local vel = slapVelMultipled + origVel

    ply:SetLocalVelocity( vel )

    -- Slap current weapon out of player's hands
    self:SlapWeaponOutOfHands( ply )

    -- Emit slap sound
    self:SlapSound()
    -- Emit hurt sound on player
    ply:EmitSound( table.Random( self.Sounds.Hurt ), 50, math.random( 92, 108 ) ) -- don't allow ply's pitch/level to be modified

    local oldPunchAng = ply:GetViewPunchAngles()
    local punchAng = oldPunchAng + Angle( -3, 2, 0 )
    self:ViewPunchSlapper( ply, punchAng )

end

function SWEP:SlapNPC( ent, tr )
    local vec = ( tr.HitPos - tr.StartPos ):GetNormal()

    -- Apply slap velocity to NPC
    if ent.GetPhysicsObject then
        local obj = ent:GetPhysicsObject()
        if obj:IsValid() then
            local force = math.Clamp( GetConVar( "slappers_base_force" ):GetInt() - obj:GetMass(), 0, math.huge )
            local vel = vec * force * 4.75
            vel.z = math.Clamp( vel.z, 50, 500 ) -- don't get out of hand!

            local velMultiplied = vel * self:ForceMul()

            ent:SetLocalVelocity( velMultiplied )

        end
    end

    -- Filter entities that respond to slaps
    if self.NPCFilter[ent:GetClass()] then
        ent:EmitSound( table.Random( self.Sounds.Hurt ), 50, math.random( 95, 105 ) ) -- don't mod this either
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
    self:SlapSound()

end

function SWEP:SlapWorld( _, tr )
    self:GetOwner():EmitSound( table.Random( self.Sounds.HitWorld ), self:Level( 80 ), self:Pitch( math.random( 92, 108 ) ) )
    self:SlapSound()
    -- i just slapped a wall! that oughta hurt!
    local damage = math.random( 1, 2 ) * self:ForceMul() -- damage is proportional to the swep's force
    local dmginfo = DamageInfo()
    dmginfo:SetDamageType( DMG_CLUB )
    dmginfo:SetAttacker( self:GetOwner() )
    dmginfo:SetInflictor( game.GetWorld() )
    dmginfo:SetDamage( damage )
    self:GetOwner():TakeDamageInfo( dmginfo )

    -- Apply force to self
    local origVel = self:GetOwner():GetVelocity()
    local vec = ( tr.HitPos - tr.StartPos ):GetNormal()
    local mul = GetConVar( "slappers_base_force" ):GetInt()
    local mulMultiplied = mul * self:ForceMul() -- double!!!
    local slapVel = -vec * mulMultiplied
    local vel = slapVel * 0.6 + origVel
    self:GetOwner():SetLocalVelocity( vel )

end

local interactables = {
    func_door = true,
    func_button = true,
    gmod_button = true,
    gmod_wire_button = true,
    func_door_rotating = true,
    prop_door_rotating = true,
}

function SWEP:SlapProp( ent, tr )
    local vec = ( tr.HitPos - tr.StartPos ):GetNormal()
    local damage = math.random( 4, 6 )

    if interactables[ent:GetClass()] then
        local owner = self:GetOwner()
        ent:Use( owner, owner ) -- Press button
    elseif ent:Health() > 0 then
        if ent:Health() <= damage then
            ent:Fire( "Break", "nil", 0, owner, ent )
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
        self:SlapSound()
        local mul = GetConVar( "slappers_base_force" ):GetInt() * self:ForceMul()
        local mulMultiplied = mul * math.Clamp( 100 / phys:GetMass(), 0, 1 )

        local newForce = vec * mul * mulMultiplied

        phys:ApplyForceCenter( newForce )

    else
        self:GetOwner():EmitSound( table.Random( self.Sounds.HitWorld ), self:Level( 80 ), self:Pitch( math.random( 92, 108 ) ) )

    end

    -- Emit slap sound
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
        if not IsValid( self ) then return end
        self:SetWeaponHoldType( self.HoldType )
    end )
end

net.Receive( "SlapAnimation", function()
    -- Make sure the player is still valid
    local ply = net.ReadEntity()
    if not IsValid( ply ) then return end

    local weapon = ply:GetActiveWeapon()
    if not IsValid( weapon ) then return end
    if not weapon.SlapAnimation then return end

    local now = CurTime()
    local nextAnim = weapon.NextSlapAnimation or 0
    if nextAnim > now then return end

    local halvedDelay = weapon.Primary.Delay / 2
    weapon.NextSlapAnimation = now + halvedDelay

    weapon:SlapAnimation()

end )

function SWEP:Slap()
    -- Broadcast third person slap
    self:SlapAnimation()

    -- Perform trace
    if not SERVER then return end

    local punchScale = 1
    local swepOwner = self:GetOwner()
    local shootPos = swepOwner:GetShootPos()
    local vm = swepOwner:GetViewModel()

    -- Use view model slap animation
    self:SendWeaponAnim( ACT_VM_PRIMARYATTACK_2 )
    vm:SetPlaybackRate( 1.5 ) -- faster slap

    -- Trace for slap hit
    local tr = util.TraceHull( {
        start = shootPos,
        endpos = shootPos + swepOwner:GetAimVector() * 54,
        mins = self.Mins,
        maxs = self.Maxs,
        filter = swepOwner
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
        swepOwner:EmitSound( self.Sounds.Miss, self:Level( 80 ), self:Pitch( math.random( 92, 108 ) ) )
        punchScale = 0.1
    end

    local side = 4
    if not self.PrimaryAttacking then
        side = -side
    end

    local oldPunchAng = swepOwner:GetViewPunchAngles()
    local punchAng = oldPunchAng + Angle( -6, side, 0 ) * punchScale
    self:ViewPunchSlapper( swepOwner, punchAng )
end

--[[
	Slapping
]]
function SWEP:PrimaryAttack()
    if game.SinglePlayer() then
        self:CallOnClient( "PrimaryAttack", "" )
    end

    -- Left handed slap
    self.PrimaryAttacking = true
    self.ViewModelFlip = false
    self:Slap()
    self:SetNextPrimaryFire( CurTime() + self.Primary.Delay )
end

function SWEP:SecondaryAttack()
    if game.SinglePlayer() then
        self:CallOnClient( "SecondaryAttack", "" )
    end

    -- Right handed slap
    self.PrimaryAttacking = false
    self.ViewModelFlip = true
    self:Slap()
    self:SetNextSecondaryFire( CurTime() + self.Primary.Delay )
end
