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


CreateConVar( "cfc_parachute_fall_speed", 200, { FCVAR_REPLICATED, FCVAR_ARCHIVE }, "Target fall speed while in a parachute.", 0, 50000 )
CreateConVar( "cfc_parachute_fall_lerp", 2, { FCVAR_REPLICATED, FCVAR_ARCHIVE }, "How quickly a parachute will reach its target fall speed. Higher values are faster.", 0, 100 )
CreateConVar( "cfc_parachute_horizontal_speed", 80, { FCVAR_REPLICATED, FCVAR_ARCHIVE }, "How quickly you move in a parachute.", 0, 50000 )
CreateConVar( "cfc_parachute_horizontal_speed_limit", 700, { FCVAR_REPLICATED, FCVAR_ARCHIVE }, "Max horizontal speed of a parachute.", 0, 50000 )
CreateConVar( "cfc_parachute_sprint_boost", 1.25, { FCVAR_REPLICATED, FCVAR_ARCHIVE }, "How much of a horizontal boost you get in a parachute while sprinting.", 1, 10 )
CreateConVar( "cfc_parachute_handling", 4, { FCVAR_REPLICATED, FCVAR_ARCHIVE }, "Improves parachute handling by making it easier to brake or chagne directions. 1 gives no handling boost, 0-1 reduces handling.", 0, 10 )
CreateConVar( "cfc_parachute_expiration_delay", 5, { FCVAR_REPLICATED, FCVAR_ARCHIVE }, "How long until a parachute will delete itself after being closed.", 0.5, 30 )

CreateConVar( "cfc_parachute_max_lurch", 125, { FCVAR_REPLICATED, FCVAR_ARCHIVE }, "Maximum downwards force a parachute can receive from weapon-induced lurches.", 0, 50000 )
CreateConVar( "cfc_parachute_max_total_lurch", 400, { FCVAR_REPLICATED, FCVAR_ARCHIVE }, "Maximum downwards velocity before a parachute stops being affected by lurch. Puts a soft-cap on how fast you plummet from shooting weapons.", 0, 50000 )
CreateConVar( "cfc_parachute_shoot_lurch_chance", 0.1, { FCVAR_REPLICATED, FCVAR_ARCHIVE }, "The chance for a parachute to lurch downwards when the player shoots a bullet.", 0, 1 )

CreateConVar( "cfc_parachute_space_equip_speed", 300, { FCVAR_ARCHIVE, FCVAR_REPLICATED }, "The minimum falling speed required for a player to space-equip a parachute.", 0, 50000 )
CreateConVar( "cfc_parachute_space_equip_sv", 1, { FCVAR_ARCHIVE, FCVAR_REPLICATED }, "Press spacebar while falling to quickly equip a parachute. Defines the default value for players.", 0, 1 )
CreateConVar( "cfc_parachute_space_equip_double_sv", 0, { FCVAR_ARCHIVE, FCVAR_REPLICATED }, "Double tap spacebar to equip parachutes, instead of a single press. Defines the default value for players.", 0, 1 )
CreateConVar( "cfc_parachute_space_equip_redundancy_sv", 1, { FCVAR_ARCHIVE, FCVAR_REPLICATED }, "Makes space-equip still play the ready sound and require fast falling speed to activate when a player has recently used a parachute. Defines the default value for players.", 0, 1 )

CreateConVar( "cfc_parachute_quick_close_advanced_sv", 0, { FCVAR_ARCHIVE, FCVAR_REPLICATED }, "Makes quick-close require walk and crouch to be pressed together. Defines the default value for players.", 0, 1 )
