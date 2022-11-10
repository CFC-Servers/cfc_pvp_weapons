# cfc_pvp_weapons

## Server Convars

| Convar | Description | Default |
| :---: | :---: | :---: |
| cfc_shaped_charge_chargehealth | Health of placed charges. | 100 |
| cfc_shaped_charge_maxcharges | Maxmium amount of charges active per person at once. | 1 |
| cfc_shaped_charge_timer | The time it takes for a charges to detonate. | 10 |
| cfc_shaped_charge_blastdamage | The damage the explosive does to players when it explodes. | 0 |
| cfc_shaped_charge_blastrange | The damage range the explosion has. | 100 |
| cfc_shaped_charge_tracerange | The range the prop breaking explosion has. | 100 |
| cfc_parachute_fall_speed | Target fall speed while in a furled parachute. | 450 |
| cfc_parachute_fall_speed_unfurled | Target fall speed while in an unfurled parachute. | 200 |
| cfc_parachute_fall_lerp | How quickly a parachute will reach its target fall speed. | 0.8 |
| cfc_parachute_horizontal_speed | How quickly you move in a furled parachute. | 110 |
| cfc_parachute_horizontal_speed_unfurled | How quickly you move in an unfurled parachute. | 300 |
| cfc_parachute_horizontal_speed_unstable | How well you can control a parachute while holding another weapon. | 80 |
| cfc_parachute_horizontal_speed_limit | Max horizontal speed of a parachute. | 1000 |
| cfc_parachute_sprint_boost | How much of a horizontal boost you get in a parachute while sprinting. | 1.5 |
| cfc_parachute_handling | Improves parachute handling by making it easier to brake or chagne directions. 1 gives no handling boost, 0-1 reduces handling. | 2.5 |
| cfc_parachute_destabilize_min_gap | Minimum time between direction changes while a parachute destabilizes, in seconds. | 0.1 |
| cfc_parachute_destabilize_max_gap | Maximum time between direction changes while a parachute destabilizes, in seconds. | 2.5 |
| cfc_parachute_destabilize_max_direction_change | Maximum angle change in a parachute's direction while it is destabilized. | 30 |
| cfc_parachute_destabilize_max_lurch | Maximum downwards force a parachute can receive from random lurches while destabilized. | 150 |
| cfc_parachute_destabilize_max_fall_lurch | Maximum downwards velocity before a parachute stops being affected by lurch. Puts a soft-cap on how fast you plummet from shooting weapons. | 550 |
| cfc_parachute_destabilize_lurch_chance | The chance for an unstable parachute to lurch downwards when a direction change occurs. | 0.2 |
| cfc_parachute_destabilize_shoot_lurch_chance | The chance for an unstable parachute to lurch downwards when the player shoots a bullet. | 0.1 |
| cfc_parachute_destabilize_shoot_change_chance | The chance for an unstable parachute's direction to change when the player shoots a bullet. | 0.25 |
| cfc_parachute_lfs_eject_height | The minimum height above the ground a player must be for LFS eject events to trigger (e.g. auto-parachute and rendezook launch). | 500 |
| cfc_parachute_lfs_eject_launch_force | The upwards force applied to players when they launch out of an LFS plane. | 1100 |
| cfc_parachute_lfs_eject_launch_bias | How many degrees the LFS eject launch should course-correct the player's trajectory to send them straight up, for if their plane is tilted. | 25 |
| cfc_parachute_lfs_eject_stability_time | How many seconds a player is immune to parachute instability when they launch out of an LFS plane. | 5 |
| cfc_parachute_lfs_enter_radius | How close a player must be to enter an LFS if they are in a parachute and regular use detection fails. Makes it easier to get inside of an LFS for performing a Rendezook. | 800 |

## Client Convars

| Convar | Description | Default |
| :---: | :---: | :---: |
| cfc_parachute_design | Your selected parachute design. | 1 |
| cfc_parachute_lfs_auto_equip | Whether or not to auto-equip a parachute when ejecting from an LFS plane in the air. | 1 |
| cfc_parachute_lfs_eject_launch | Whether or not to launch up high when ejecting from an LFS plane in the air. Useful for pulling off a Rendezook. | 1 |
| cfc_parachute_unfurl_toggle | When enabled, pressing jump will toggle the unfurl state instead of holding it. Jumps won't toggle unfurl if chute is closed. | 0 |
| cfc_parachute_unfurl_invert | Whether or not your parachute will be unfurled by default. Don't forget to open it! | 1 |

## Credits

- [Slap swep](https://steamcommunity.com/sharedfiles/filedetails/?id=1052253533) - Workshop
