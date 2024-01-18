CreateConVar( "cfc_parachute_fall_speed", 200, { FCVAR_ARCHIVE }, "Target fall speed while in a parachute.", 0, 50000 )
CreateConVar( "cfc_parachute_fall_lerp", 2, { FCVAR_ARCHIVE }, "How quickly a parachute will reach its target fall speed. Higher values are faster.", 0, 100 )
CreateConVar( "cfc_parachute_horizontal_speed", 80, { FCVAR_ARCHIVE }, "How quickly you move in a parachute.", 0, 50000 )
CreateConVar( "cfc_parachute_horizontal_speed_limit", 700, { FCVAR_ARCHIVE }, "Max horizontal speed of a parachute.", 0, 50000 )
CreateConVar( "cfc_parachute_sprint_boost", 1.25, { FCVAR_ARCHIVE }, "How much of a horizontal boost you get in a parachute while sprinting.", 1, 10 )
CreateConVar( "cfc_parachute_handling", 4, { FCVAR_ARCHIVE }, "Improves parachute handling by making it easier to brake or chagne directions. 1 gives no handling boost, 0-1 reduces handling.", 0, 10 )
CreateConVar( "cfc_parachute_expiration_delay", 5, { FCVAR_ARCHIVE }, "How long until a parachute will delete itself after being closed.", 0.5, 30 )

CreateConVar( "cfc_parachute_min_lurch", 30, { FCVAR_ARCHIVE }, "Minimum downwards force a parachute can receive from weapon-induced lurches.", 0, 50000 )
CreateConVar( "cfc_parachute_max_lurch", 100, { FCVAR_ARCHIVE }, "Maximum downwards force a parachute can receive from weapon-induced lurches.", 0, 50000 )
CreateConVar( "cfc_parachute_max_total_lurch", 400, { FCVAR_ARCHIVE }, "Maximum downwards velocity before a parachute stops being affected by lurch. Puts a soft-cap on how fast you plummet from shooting weapons.", 0, 50000 )
CreateConVar( "cfc_parachute_shoot_lurch_chance", 0.2, { FCVAR_ARCHIVE }, "The chance for a parachute to lurch downwards when the player shoots a bullet.", 0, 1 )

CreateConVar( "cfc_parachute_space_equip_speed", 300, { FCVAR_ARCHIVE }, "The minimum falling speed required for a player to space-equip a parachute.", 0, 50000 )
