-- Optional LFS integration.

local IsValid = IsValid


local function trySetupLFS()
    -- Server settings.
    local LFS_EJECT_HEIGHT = CreateConVar( "cfc_parachute_lfs_eject_height", 500, { FCVAR_ARCHIVE }, "The minimum height above the ground a player must be for LFS eject events to trigger (e.g. auto-parachute and rendezook launch).", 0, 50000 )
    local LFS_EJECT_LAUNCH_FORCE = CreateConVar( "cfc_parachute_lfs_eject_launch_force", 1100, { FCVAR_ARCHIVE }, "The upwards force applied to players when they launch out of an LFS plane.", 0, 50000 )

    -- Server preferences of client settings.
    local LFS_EJECT_SV = CreateConVar( "cfc_parachute_lfs_eject_sv", 1, { FCVAR_ARCHIVE, FCVAR_REPLICATED }, "Whether or not exiting mid-air LFS planes will launch the player up with a parachute. Defines the default value for players.", 0, 1 )


    local function lfsEject( ply, lfsPlane )
        local force = LFS_EJECT_LAUNCH_FORCE:GetFloat()
        local dir = lfsPlane:GetUp()
        local lfsVel = lfsPlane:GetVelocity() * 1.2

        CFC_Parachute.OpenParachute( ply )

        timer.Simple( 0.01, function()
            if not IsValid( ply ) then return end

            ply:SetVelocity( dir * force + lfsVel )
        end )
    end


    hook.Add( "PlayerLeaveVehicle", "CFC_Parachute_TryLFSEject", function( ply, vehicle )
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
end


hook.Add( "InitPostEntity", "CFC_Parachute_SetupLFS", function()
    if not simfphys or not simfphys.LFS then return end

    trySetupLFS()
end )
