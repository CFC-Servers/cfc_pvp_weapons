-- Optional LFS integration.

local IsValid = IsValid


local function trySetupLFS()
    -- Server settings.
    local LFS_EJECT_HEIGHT = CreateConVar( "cfc_parachute_lfs_eject_height", 500, { FCVAR_REPLICATED, FCVAR_ARCHIVE }, "The minimum height above the ground a player must be for LFS eject events to trigger (e.g. auto-parachute and rendezook launch).", 0, 50000 )
    local LFS_EJECT_LAUNCH_FORCE = CreateConVar( "cfc_parachute_lfs_eject_launch_force", 1100, { FCVAR_REPLICATED, FCVAR_ARCHIVE }, "The upwards force applied to players when they launch out of an LFS plane.", 0, 50000 )
    local LFS_EJECT_LAUNCH_BIAS = CreateConVar( "cfc_parachute_lfs_eject_launch_bias", 25, { FCVAR_REPLICATED, FCVAR_ARCHIVE }, "How many degrees the LFS eject launch should course-correct the player's trajectory to send them straight up, for if their plane is tilted.", 0, 90 )
    local LFS_ENTER_RADIUS = CreateConVar( "cfc_parachute_lfs_enter_radius", 800, { FCVAR_REPLICATED, FCVAR_ARCHIVE }, "How close a player must be to enter an LFS if they are in a parachute and regular use detection fails. Makes it easier to get inside of an LFS for performing a Rendezook.", 0, 50000 )

    -- Server preferences of client settings.
    local LFS_EJECT_SV = CreateConVar( "cfc_parachute_lfs_eject_sv", 1, { FCVAR_ARCHIVE, FCVAR_REPLICATED }, "Whether or not exiting mid-air LFS planes will launch the player up with a parachute. Defines the default value for players.", 0, 1 )


    local function lfsEject( ply, lfsPlane )
        local force = LFS_EJECT_LAUNCH_FORCE:GetFloat()
        local bias = LFS_EJECT_LAUNCH_BIAS:GetFloat()
        local dir = lfsPlane:GetUp()

        if dir.z >= 0 then -- Biasing the direction if it's tilted down would be pointless
            local forwardAng = lfsPlane:GetAngles()
            local pitchCorrect = math.Clamp( forwardAng.p, -bias, bias )
            local rollCorrect = math.Clamp( -forwardAng.r, -bias, bias )

            forwardAng:RotateAroundAxis( lfsPlane:GetRight(), pitchCorrect )
            forwardAng:RotateAroundAxis( lfsPlane:GetForward(), rollCorrect )

            dir = forwardAng:Up()
        end

        timer.Simple( 0.01, function()
            if not IsValid( ply ) then return end

            local lfsVel = IsValid( lfsPlane ) and lfsPlane:GetVelocity() * 1.2 or Vector( 0, 0, 0 )

            ply:SetVelocity( dir * force + lfsVel )
        end )
    end


    hook.Add( "PlayerLeaveVehicle", "CFC_Parachute_TryLFSEject", function( ply, vehicle )
        if not IsValid( ply ) then return end
        if not ply:IsPlayer() then return end
        if not ply:Alive() then return end
        if not IsValid( vehicle ) then return end

        local lfsPlane = vehicle.LFSBaseEnt
        if not IsValid( lfsPlane ) then return end

        if hook.Run( "CFC_Parachute_CanLFSEject", ply, vehicle, lfsPlane ) == false then return end

        lfsEject( ply, lfsPlane )
    end )

    hook.Add( "CFC_Parachute_CanLFSEject", "CFC_Parachute_CheckPreferences", function( ply, _vehicle, _lfsPlane )
        local ejectEnabled = CFC_Parachute.GetConVarPreference( ply, "cfc_parachute_lfs_eject", LFS_EJECT_SV )

        if not ejectEnabled then return false end
    end )

    hook.Add( "CFC_Parachute_CanLFSEject", "CFC_Parachute_IsInTheAir", function( ply, vehicle, lfsPlane )
        local minHeight = LFS_EJECT_HEIGHT:GetFloat()
        if minHeight <= 0 then return end

        local hull = ply:OBBMaxs() * Vector( 1, 1, 0 ) + Vector( 0, 0, 1 )
        local plyPos = ply:GetPos()

        local mainEnts = { vehicle, lfsPlane, ply }
        local filterTable = constraint.GetAllConstrainedEntities( lfsPlane )

        for _, v in ipairs( mainEnts ) do
            table.insert( filterTable, v )
        end

        local tr = util.TraceHull( {
            start = plyPos,
            endpos = plyPos + Vector( 0, 0, -minHeight ),
            mins = -hull,
            maxs = hull,
            filter = filterTable,
        } )

        if tr.Hit then return false end
    end )

    hook.Add( "FindUseEntity", "CFC_Parachute_LFSEasyEnter", function( ply, ent )
        if IsValid( ent ) then return end -- Don't run if the player is looking directly at something already.
        if not IsValid( ply ) then return end
        if not ply:IsPlayer() then return end
        if ply:InVehicle() then return end -- Already in a vehicle.

        -- Check if the player is in a parachute.
        local chute = ply.cfcParachuteChute
        if not IsValid( chute ) then return end
        if not chute._chuteIsOpen then return end

        -- Check for a nearby LFS plane to use.
        local radiusSqr = LFS_ENTER_RADIUS:GetFloat() ^ 2
        local lfsPlanes = ents.FindByClass( "lunasflightschool_*" )
        local plyPos = ply:GetPos()

        for i = 1, #lfsPlanes do
            local plane = lfsPlanes[i]
            if not plane.GetDriverSeat then continue end -- Not a plane, just some other LFS entity.

            if plane:GetPos():DistToSqr( plyPos ) <= radiusSqr then
                return plane
            end
        end
    end )
end


hook.Add( "InitPostEntity", "CFC_Parachute_SetupLFS", function()
    if not simfphys or not simfphys.LFS then return end

    trySetupLFS()
end )
