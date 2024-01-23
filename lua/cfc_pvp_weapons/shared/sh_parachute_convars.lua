CFC_Parachute = CFC_Parachute or {}

CFC_Parachute.DesignMaterialPrefix = "models/cfc/parachute/parachute_"
CFC_Parachute.DesignMaterialNames = {
    "base",
    "red",
    "orange",
    "yellow",
    "green",
    "teal",
    "blue",
    "purple",
    "magenta",
    "white",
    "black",
    "brown",
    "rainbow",
    "camo",
    "camo_tan",
    "camo_brown",
    "camo_blue",
    "camo_white",
    "cfc",
    "phatso",
    "missing",
    "troll",
    "troll_gross",
    "saul_goodman",
    "the_click",
    "biter",
    "no_kills",
}
CFC_Parachute.DesignMaterialCount = #CFC_Parachute.DesignMaterialNames

CFC_Parachute.DesignMaterialProxyInfo = { -- Proxy info, indexed by material name. glua is unable to get this info automatically from Material objects.
    biter = {
        AnimatedTexture = {
            animatedTextureVar = "$basetexture",
            animatedTextureFrameNumVar = "$frame",
            animatedTextureFrameRate = 6.25,
        },
    },
}


CreateConVar( "cfc_parachute_space_equip_sv", 1, { FCVAR_ARCHIVE, FCVAR_REPLICATED }, "Press spacebar while falling to quickly equip a parachute. Defines the default value for players.", 0, 1 )
CreateConVar( "cfc_parachute_space_equip_double_sv", 0, { FCVAR_ARCHIVE, FCVAR_REPLICATED }, "Double tap spacebar to equip parachutes, instead of a single press. Defines the default value for players.", 0, 1 )

CreateConVar( "cfc_parachute_quick_close_advanced_sv", 0, { FCVAR_ARCHIVE, FCVAR_REPLICATED }, "Makes quick-close require walk and crouch to be pressed together. Defines the default value for players.", 0, 1 )
