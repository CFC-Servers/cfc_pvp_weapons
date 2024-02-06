AddCSLuaFile()

if CLIENT then
    hook.Add( "PostDrawTranslucentRenderables", "cfc_simple_base", function( _depth, skybox, skybox3d )
        if skybox or skybox3d then
            return
        end

        for _, ply in ipairs( player.GetAll() ) do
            if ply:IsDormant() or ply:InVehicle() then
                continue
            end

            local weapon = ply:GetActiveWeapon()

            if not IsValid( weapon ) or weapon:IsDormant() or not weapon.SimpleWeapon then
                continue
            end

            if not weapon.PostDrawTranslucentRenderables then
                continue
            end

            weapon:PostDrawTranslucentRenderables()
        end
    end )
end
