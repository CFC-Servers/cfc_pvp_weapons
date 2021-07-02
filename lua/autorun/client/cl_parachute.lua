CFC_Parachute = CFC_Parachute or {}

CFC_Parachute.DesignMaterials = false
CFC_Parachute.DesignMaterialNames = false
CFC_Parachute.DesignMaterialCount = false

local DESIGN_MATERIALS
local DESIGN_MATERIAL_NAMES
local DESIGN_MATERIAL_COUNT

local DESIGN_CHOICE = CreateConVar( "cfc_parachute_design", 1, { FCVAR_ARCHIVE, FCVAR_USERINFO, FCVAR_SERVER_CAN_EXECUTE, FCVAR_NEVER_AS_STRING }, "Your selected parachute design.", 1, 50000 )

function CFC_Parachute.CreateDesignPreview( x, y, ind, panel )
    local icon = vgui.Create( "ContentIcon", panel )
    icon:SetPos( x, y )
    icon:SetName( DESIGN_MATERIAL_NAMES[ind] )
    icon:SetMaterial( DESIGN_MATERIALS[ind] )

    icon.designInd = ind
    
    icon.DoClick = function()
        LocalPlayer():ConCommand( "cfc_parachute_design " .. ind )
    end

    return icon
end

function CFC_Parachute.OpenDesignMenu()
    local window

    if window then
        window:Show()
        window:MakePopup()

        return
    end

    local windowWidth = 800
    local windowHeight = 600

    window = vgui.Create( "DFrame" )
    window:SetSize( windowWidth, windowHeight )
    window:Center()
    window:SetTitle( "CFC Parachute Designs" )
    window:SetDeleteOnClose( false )
    window:MakePopup()

    scrollPanel = vgui.Create( "DScrollPanel", window )
    scrollPanel:SetPos( 0, 10 )
    scrollPanel:SetSize( windowWidth, windowHeight )

    window.Paint = function( _, w, h )
        draw.RoundedBox( 8, 0, 0, w, h, Color( 36, 41, 67, 255 ) )
        draw.RoundedBox( 8, 0, 0, w, 25, Color( 42, 47, 74, 255 ) )
    end

    local x = 0
    local y = 0
    local designIconOffsetY = 30
    local designIconWidth = 120

    for i = 1, CFC_Parachute.DesignMaterialCount do
        if ( x + 1 ) * designIconWidth >= windowWidth then
            x = 0
            y = y + 1
        end

        CFC_Parachute.CreateDesignPreview( x * designIconWidth, y * designIconWidth + designIconOffsetY, i, scrollPanel )

        x = x + 1
    end
end

cvars.AddChangeCallback( "cfc_parachute_design", function( _, old, new )
    net.Start( "CFC_Parachute_SelectDesign" )
    net.WriteInt( math.floor( old ), 17 )
    net.WriteInt( math.floor( new ), 17 )
    net.SendToServer()
end )

net.Receive( "CFC_Parachute_DefineChuteDir", function()
    local chute = net.ReadEntity()
    local chuteDir = net.ReadVector()

    chute:SetChuteDirection( chuteDir )
end )

net.Receive( "CFC_Parachute_DefineChuteUnfurlStatus", function()
    local chute = net.ReadEntity()
    local unfurlState = net.ReadBool()

    chute:SetUnfurlStatus( unfurlState )
end )

net.Receive( "CFC_Parachute_DefineDesigns", function()
    DESIGN_MATERIALS = net.ReadTable()
    DESIGN_MATERIAL_NAMES = net.ReadTable()
    DESIGN_MATERIAL_COUNT = net.ReadInt( 17 )

    CFC_Parachute.DesignMaterials = DESIGN_MATERIALS
    CFC_Parachute.DesignMaterialNames = DESIGN_MATERIAL_NAMES
    CFC_Parachute.DesignMaterialCount = DESIGN_MATERIAL_COUNT
end )

net.Receive( "CFC_Parachute_SelectDesign", function()
    net.Start( "CFC_Parachute_SelectDesign" )
    net.WriteInt( 1, 17 )
    net.WriteInt( DESIGN_CHOICE:GetInt(), 17 )
    net.SendToServer()
end )

net.Receive( "CFC_Parachute_GrabChuteStraps", function()
    local ply = net.ReadEntity()
    local state = net.ReadBool()

    ply:SetIK( not state )

    if state then
        ply:AnimRestartGesture( GESTURE_SLOT_CUSTOM, ACT_GMOD_NOCLIP_LAYER, false )
        ply:AnimRestartGesture( GESTURE_SLOT_JUMP, ACT_HL2MP_IDLE_PASSIVE, false )
    else
        ply:AnimResetGestureSlot( GESTURE_SLOT_CUSTOM )
        ply:AnimResetGestureSlot( GESTURE_SLOT_JUMP )
    end

    local rightUpperarm = ply:LookupBone( "ValveBiped.Bip01_R_Upperarm" )
    local rightForearm = ply:LookupBone( "ValveBiped.Bip01_R_Forearm" )
    local rightHand = ply:LookupBone( "ValveBiped.Bip01_R_Hand" )
    local leftUpperarm = ply:LookupBone( "ValveBiped.Bip01_L_Upperarm" )
    local leftForearm = ply:LookupBone( "ValveBiped.Bip01_L_Forearm" )
    local leftHand = ply:LookupBone( "ValveBiped.Bip01_L_Hand" )

    if not rightUpperarm or not rightForearm or not rightHand or not leftUpperarm or not leftForearm or not leftHand then return end

    if state then
        ply:ManipulateBoneAngles( rightUpperarm, Angle( 127.3, 331.3, 368.5 ) )
        ply:ManipulateBoneAngles( rightForearm, Angle( -6.8, 41.4, 57.5 ) )
        ply:ManipulateBoneAngles( rightHand, Angle( 0, 26.7, 25.4 ) )
        ply:ManipulateBoneAngles( leftUpperarm, Angle( -72.1, -166, 127.3 ) )
        ply:ManipulateBoneAngles( leftForearm, Angle( -11, 7.2, 26.5 ) )
        ply:ManipulateBoneAngles( leftHand, Angle( 0, 8.7, 0 ) )
    else
        local resetAng = Angle( 0, 0, 0 )

        ply:ManipulateBoneAngles( rightUpperarm, resetAng )
        ply:ManipulateBoneAngles( rightForearm, resetAng )
        ply:ManipulateBoneAngles( rightHand, resetAng )
        ply:ManipulateBoneAngles( leftUpperarm, resetAng )
        ply:ManipulateBoneAngles( leftForearm, resetAng )
        ply:ManipulateBoneAngles( leftHand, resetAng )
    end
end )
