CreateConVar( "cfc_parachute_fall_speed", 200, { FCVAR_ARCHIVE }, "Target fall speed while in a parachute.", 0, 50000 )
CreateConVar( "cfc_parachute_fall_lerp", 2, { FCVAR_ARCHIVE }, "How quickly a parachute will reach its target fall speed. Higher values are faster.", 0, 100 )
CreateConVar( "cfc_parachute_horizontal_speed", 80, { FCVAR_ARCHIVE }, "How quickly you move in a parachute.", 0, 50000 )
CreateConVar( "cfc_parachute_horizontal_speed_limit", 700, { FCVAR_ARCHIVE }, "Max horizontal speed of a parachute.", 0, 50000 )
CreateConVar( "cfc_parachute_sprint_boost", 1.25, { FCVAR_ARCHIVE }, "How much of a horizontal boost you get in a parachute while sprinting.", 1, 10 )
CreateConVar( "cfc_parachute_handling", 4, { FCVAR_ARCHIVE }, "Improves parachute handling by making it easier to brake or chagne directions. 1 gives no handling boost, 0-1 reduces handling.", 0, 10 )
CreateConVar( "cfc_parachute_expiration_delay", 5, { FCVAR_ARCHIVE }, "How long until a parachute will delete itself after being closed.", 0.5, 30 )

CreateConVar( "cfc_parachute_space_equip_speed", 100, { FCVAR_ARCHIVE }, "The minimum falling speed required for a player to space-equip a parachute.", 0, 50000 )