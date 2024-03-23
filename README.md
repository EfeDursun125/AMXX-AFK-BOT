# Amx Mod X AFK Bot
This is AFK Bot amxmodx plugin for Counter Strike 1.6

# CVars
- amx_afk_manager_version // shows the plugin version
- amx_afk_manager_time "60.0" // idle time to start controlling players
- amx_afk_manager_aim_speed "24.0" // afk aim speed
- amx_afk_manager_manual_afk "1" // can afk players be afk manually by using !afk command?, 1 = yes, 0 = no

# Natives
is_user_afk(id) = returns 1 if is user afk, 0 otherwise
get_user_afk_time(id) = returns how long the player has been afk
get_total_afk_count() = returns the number of afk players in the server
