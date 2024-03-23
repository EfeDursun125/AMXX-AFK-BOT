#if defined _vip_manager_included
	#endinput
#endif
#define _vip_manager_included

/**
 * Returns whether a player is a afk.
 *
 * @param id	Player index.
 * @return		True if it is, false otherwise.
 */
native is_user_afk(id)

/**
 * Returns a afk's time.
 *
 * @param id	Player index.
 * @return		Player's afk time.
 */
native get_user_afk_time(id)

/**
 * Returns the total afk count on the server.
 */
native get_total_afk_count()
