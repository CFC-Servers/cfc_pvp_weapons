if SERVER then
    AddCSLuaFile( "shared.lua" )
    resource.AddFile( "models/weapons/v_watch.mdl" )
    resource.AddFile( "materials/models/weapons/v_arms.vmt" )
    resource.AddFile( "materials/models/weapons/watch.vmt" )

    for i = 1, 9 do
        resource.AddFile( string.format( "sound/elevator/effects/slap_hit0%s.wav", i ) )
    end

    CreateConVar( "slappers_slap_weapons", 0, FCVAR_REPLICATED, "Slap weapons out of players' hands" )
    CreateConVar( "slappers_force", 800, FCVAR_REPLICATED, "Force of the slappers" )
    util.AddNetworkString( "SlapAnimation" )
end

SWEP.Spawnable = true
SWEP.AdminSpawnable = true
SWEP.PrintName = "Slappers"
SWEP.Slot = 1
SWEP.SlotPos = 0
SWEP.ViewModel = Model( "models/weapons/v_watch.mdl" )
SWEP.WorldModel = ""
SWEP.HoldType = "normal"

SWEP.Primary = {
    ClipSize = -1,
    Delay = 0.8,
    DefaultClip = -1,
    Automatic = false,
    Ammo = "none"
}

SWEP.Secondary = SWEP.Primary

SWEP.Sounds = {
    Miss = Sound( "Weapon_Knife.Slash" ),
    HitWorld = Sound( "Default.ImpactSoft" ),
    Hurt = { Sound( "npc_citizen.ow01" ), Sound( "npc_citizen.ow02" ) },
    Slap = { Sound( "elevator/effects/slap_hit01.wav" ), Sound( "elevator/effects/slap_hit02.wav" ), Sound( "elevator/effects/slap_hit03.wav" ), Sound( "elevator/effects/slap_hit04.wav" ), Sound( "elevator/effects/slap_hit05.wav" ), Sound( "elevator/effects/slap_hit06.wav" ), Sound( "elevator/effects/slap_hit07.wav" ), Sound( "elevator/effects/slap_hit08.wav" ), Sound( "elevator/effects/slap_hit09.wav" ) }
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
end

function SWEP:SecondaryAttack()
    if game.SinglePlayer() then
        self:CallOnClient( "SecondaryAttack", "" )
    end

    -- Right handed slap
    self.ViewModelFlip = true
    self:Slap()
end

function SWEP:Slap()
    -- Broadcast third person slap
    self:SlapAnimation()

    -- Perform trace
    if SERVER then
        -- Use view model slap animation
        self:SendWeaponAnim( ACT_VM_PRIMARYATTACK_2 )

        -- Trace for slap hit
        local tr = util.TraceHull( {
            start = self:GetOwner():GetShootPos(),
            endpos = self:GetOwner():GetShootPos() + self:GetOwner():GetAimVector() * 40,
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
                self:SlapWorld()
            else
                self:SlapProp( ent, tr )
            end
        else
            self:GetOwner():EmitSound( self.Sounds.Miss, 80, 100 )
        end
    end

    self:SetNextPrimaryFire( CurTime() + self.Primary.Delay )
    self:SetNextSecondaryFire( CurTime() + self.Primary.Delay )
end

function SWEP:SlapPlayer( ply, tr )
    local vec = ( tr.HitPos - tr.StartPos ):GetNormal()
    -- Emit hurt sound on player
    ply:EmitSound( table.Random( self.Sounds.Hurt ), 50, 100 )
    -- Apply force to player
    ply:SetLocalVelocity( vec * GetConVar( "slappers_force" ):GetInt() )
    -- Slap current weapon out of player's hands
    self:SlapWeaponOutOfHands( ply )
    -- Emit slap sound
    self:GetOwner():EmitSound( table.Random( self.Sounds.Slap ), 80, 100 )
end

function SWEP:SlapNPC( ent, tr )
    local vec = ( tr.HitPos - tr.StartPos ):GetNormal()
    -- Apply slap velocity to NPC
    local vel = vec * GetConVar( "slappers_force" ):GetInt() * 4.75
    vel.z = math.Clamp( vel.z, 0, 500 )
    ent:SetLocalVelocity( vel )

    -- Filter entities that respond to slaps
    if table.HasValue( self.NPCFilter, ent:GetClass() ) then
        ent:EmitSound( table.Random( self.Sounds.Hurt ), 50, 100 )
    end

    -- Only hurt non-friendly NPCs
    if ent:Disposition( self:GetOwner() ) ~= 3 then
        -- Damage potential enemies
        local dmginfo = DamageInfo()
        dmginfo:SetDamagePosition( tr.HitPos )
        dmginfo:SetDamageType( DMG_CLUB )
        dmginfo:SetAttacker( self:GetOwner() )
        dmginfo:SetInflictor( self:GetOwner() )
        dmginfo:SetDamage( math.random( 20, 25 ) )
        ent:TakeDamageInfo( dmginfo )
    end

    -- Slap current weapon out of NPC's hands
    self:SlapWeaponOutOfHands( ent )
    -- Emit slap sound
    self:GetOwner():EmitSound( table.Random( self.Sounds.Slap ), 80, 100 )
end

function SWEP:SlapWorld()
    self:GetOwner():EmitSound( self.Sounds.HitWorld, 80, 100 )
end

function SWEP:SlapProp( ent, tr )
    local vec = ( tr.HitPos - tr.StartPos ):GetNormal()
    local emitSound = self.Sounds.HitWorld
    local damage = math.random( 10, 13 )

    if ent:GetClass() == "func_button" then
        ent:Input( "Press", self:GetOwner(), self:GetOwner() ) -- Press button
    elseif string.match( ent:GetClass(), "door" ) then
        ent:Input( "Use", self:GetOwner(), self:GetOwner() ) -- Open door
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
    self:GetOwner():EmitSound( emitSound, 80, 100 )
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
    local pos = weapon:GetPos()

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

    local bonesToHide = { "ValveBiped.Bip01_L_UpperArm", "ValveBiped.Bip01_L_Clavicle", "ValveBiped.Bip01_R_UpperArm", "ValveBiped.Bip01_R_Clavicle", }

    local boneScale = vector_origin

    function SWEP:PreDrawViewModel( vm )
        if shouldHideVM then
            shouldHideVM = false
            vm:SetMaterial( "engine/occlusionproxy" )
        end

        for _, bone in ipairs( bonesToHide ) do
            local boneId = vm:LookupBone( bone )
            if not boneId then continue end
            vm:ManipulateBoneScale( boneId, boneScale )
        end
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
