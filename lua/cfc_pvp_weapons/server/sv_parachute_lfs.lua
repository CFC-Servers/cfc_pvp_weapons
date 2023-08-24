-- Optional LFS integration.

local IsValid = IsValid


local function trySetupLFS()
    -- Server settings.
    local LFS_AUTO_CHUTE_HEIGHT = CreateConVar( "cfc_parachute_lfs_eject_height", 500, { FCVAR_REPLICATED, FCVAR_ARCHIVE }, "The minimum height above the ground a player must be for LFS eject events to trigger (e.g. auto-parachute and rendezook launch).", 0, 50000 )
    local LFS_EJECT_LAUNCH_FORCE = CreateConVar( "cfc_parachute_lfs_eject_launch_force", 1100, { FCVAR_REPLICATED, FCVAR_ARCHIVE }, "The upwards force applied to players when they launch out of an LFS plane.", 0, 50000 )
    local LFS_EJECT_LAUNCH_BIAS = CreateConVar( "cfc_parachute_lfs_eject_launch_bias", 25, { FCVAR_REPLICATED, FCVAR_ARCHIVE }, "How many degrees the LFS eject launch should course-correct the player's trajectory to send them straight up, for if their plane is tilted.", 0, 90 )
    local LFS_EJECT_STABILITY_TIME = CreateConVar( "cfc_parachute_lfs_eject_stability_time", 5, { FCVAR_REPLICATED, FCVAR_ARCHIVE }, "How many seconds a player is immune to parachute instability when they launch out of an LFS plane.", 0, 50000 )
    local LFS_ENTER_RADIUS = CreateConVar( "cfc_parachute_lfs_enter_radius", 800, { FCVAR_REPLICATED, FCVAR_ARCHIVE }, "How close a player must be to enter an LFS if they are in a parachute and regular use detection fails. Makes it easier to get inside of an LFS for performing a Rendezook.", 0, 50000 )

    -- Server preferences of client settings.
    local LFS_AUTO_CHUTE_SV = CreateConVar( "cfc_parachute_lfs_auto_equip_sv", 1, { FCVAR_ARCHIVE, FCVAR_REPLICATED }, "Whether or not to auto-equip a parachute when ejecting from an LFS plane in the air. Defines the default value for players.", 0, 1 )
    local LFS_EJECT_LAUNCH_SV = CreateConVar( "cfc_parachute_lfs_eject_launch_sv", 1, { FCVAR_ARCHIVE, FCVAR_REPLICATED }, "Whether or not to launch up high when ejecting from an LFS plane in the air. Useful for pulling off a Rendezook. Defines the default value for players.", 0, 1 )


    hook.Add( "PlayerLeaveVehicle", "CFC_Parachute_LFSAirEject", function( ply, vehicle )
        if not IsValid( ply ) then return end
        if not ply:IsPlayer() then return end
        if not ply:Alive() then return end
        if not IsValid( vehicle ) then return end

        local lfsPlane = vehicle.LFSBaseEnt
        if not IsValid( lfsPlane ) then return end

        local minHeight = LFS_AUTO_CHUTE_HEIGHT:GetFloat()
        local canAutoChute

        if minHeight == 0 then
            canAutoChute = true
        else
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

            canAutoChute = not tr.Hit
        end

        if not canAutoChute then return end

        hook.Run( "CFC_Parachute_LFSAirEject", ply, vehicle, lfsPlane )
    end )

    hook.Add( "CFC_Parachute_LFSAirEject", "CFC_Parachute_LFSAutoChute", function( ply, vehicle, lfsPlane )
        if hook.Run( "CFC_Parachute_CanLFSAutoChute", ply, vehicle, lfsPlane ) == false then return end

        local wep = ply:GetWeapon( "cfc_weapon_parachute" )

        if not IsValid( wep ) then
            wep = ents.Create( "cfc_weapon_parachute" )
            wep:SetPos( Vector( 0, 0, 0 ) )
            wep:SetOwner( ply )
            wep:Spawn()

            if hook.Run( "PlayerCanPickupWeapon", ply, wep ) == false then
                wep:Remove()

                return
            end

            ply:PickupWeapon( wep )
        end

        timer.Simple( 0.1, function()
            if not IsValid( ply ) then return end
            if ply:GetActiveWeapon() == wep then return end

            ply:SelectWeapon( "cfc_weapon_parachute" )
        end )

        timer.Simple( 0.2, function()
            if not IsValid( ply ) or not IsValid( wep ) then return end

            if ply:InVehicle() then
                wep:ChangeOpenStatus( false, ply )

                return
            end

            if wep.chuteIsOpen then return end

            wep:PrimaryAttack()
        end )
    end )

    hook.Add( "CFC_Parachute_LFSAirEject", "CFC_Parachute_LFSAutoLaunch", function( ply, vehicle, lfsPlane )
        if hook.Run( "CFC_Parachute_CanLFSEjectLaunch", ply, vehicle, lfsPlane ) == false then return end

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

        ply.cfcParachuteInstabilityImmune = true

        timer.Create( "CFC_Parachute_InstabilityImmuneTimeout_" .. ply:SteamID(), LFS_EJECT_STABILITY_TIME:GetFloat(), 1, function()
            if not IsValid( ply ) then return end

            ply.cfcParachuteInstabilityImmune = false
        end )
    end )

    hook.Add( "CFC_Parachute_CanLFSAutoChute", "CFC_Parachute_CheckAutoEquipConVar", function( ply )
        local plyVal = ply:GetInfoNum( "cfc_parachute_lfs_auto_equip", 2 )
        if plyVal == 1 then return end -- Auto-equip is enabled.
        if plyVal == 0 then return false end -- Auto-equip is disabled, block it.

        -- Use server default.
        local serverDefault = LFS_AUTO_CHUTE_SV:GetString()

        if serverDefault == "0" then return false end
    end )

    hook.Add( "CFC_Parachute_CanLFSEjectLaunch", "CFC_Parachute_CheckEjectLaunchConVar", function( ply )
        local plyVal = ply:GetInfoNum( "cfc_parachute_lfs_eject_launch", 2 )
        if plyVal == 1 then return end -- Launch is enabled.
        if plyVal == 0 then return false end -- Launch is disabled, block it.

        -- Use server default.
        local serverDefault = LFS_EJECT_LAUNCH_SV:GetString()

        if serverDefault == "0" then return false end
    end )

    hook.Add( "FindUseEntity", "CFC_Parachute_LFSEasyEnter", function( ply, ent )
        if IsValid( ent ) then return end -- Don't run if the player is looking directly at something already.
        if not IsValid( ply ) then return end
        if not ply:IsPlayer() then return end
        if ply:InVehicle() then return end -- Already in a vehicle.

        -- Check if the player is in a parachute.
        local wep = ply:GetWeapon( "cfc_weapon_parachute" )
        if not IsValid( wep ) then return end
        if not wep.chuteIsOpen then return end

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
