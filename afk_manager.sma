#include <amxmodx>
#include <amxmisc>
#include <cstrike>
#include <fakemeta>
#include <fakemeta_stocks>
#include <hamsandwich>
#include <engine>
#include <fun>
#include <xs>
#define PLUGIN_VERSION "0.2"

// if you dont want to let server control players set this to false
#define CONTROL_PLAYERS true

new isAFK[33]
new Float:afkTime[33]

#if CONTROL_PLAYERS
new afkManual
new m_isSlowThink[33]
new afkAimSpeed
//new bool:isZombiePlague = false
//native zp_has_round_started()
#endif
new afkTimeLimit
public plugin_init()
{
	register_plugin("AFK Manager", PLUGIN_VERSION, "EfeDursun125")
	register_cvar("amx_afk_manager_version", PLUGIN_VERSION)
	register_clcmd("say !afk", "set_afk")
	register_clcmd("say /afk", "set_afk")
	afkTimeLimit = register_cvar("amx_afk_manager_time", "60.0")
#if CONTROL_PLAYERS
	afkAimSpeed = register_cvar("amx_afk_manager_aim_speed", "32.0")
	afkManual = register_cvar("amx_afk_manager_manual_afk", "1")
	RegisterHam(Ham_Spawn, "player", "player_spawn", 1)
#endif
}

public plugin_natives()
{
	register_library("afk_manager")
	register_native("is_user_afk", "isUserAFK")
	register_native("get_user_afk_time", "getUserAFKTime")
	register_native("get_total_afk_count", "getTotalAFKCount")
}

public plugin_cfg()
{
	//if (cvar_exists("zp_version"))
	//	isZombiePlague = true
#if CONTROL_PLAYERS
	set_cvar_num("mp_autokick", 0)
	set_cvar_num("mp_autokick_timeout", -1)
#endif
}

public isUserAFK(plugin, params)
{
	return isAFK[get_param(1)]
}

public getUserAFKTime(plugin, params)
{
	return floatround(get_gametime() - afkTime[get_param(1)])
}

public getTotalAFKCount(plugin, params)
{
	new i, count = 0
	for (i = 0; i < 33; i++)
	{
		if (!isAFK[i])
			continue

		count++
	}

	return count
}

public client_putinserver(id)
{
	afkTime[id] = get_gametime() + get_pcvar_float(afkTimeLimit)
	isAFK[id] = false
	m_isSlowThink[id] = false
}

#if AMXX_VERSION_NUM <= 182
public client_disconnect(id)
#else
public client_disconnected(id)
#endif
{
	isAFK[id] = false
	m_isSlowThink[id] = false
}

#if AMXX_VERSION_NUM <= 182
// from the zp 4.3
stock client_print_color(const target, const sender, const message[], any:...)
{
	new buffer[512]

	// send to everyone
	if (!target)
	{
		new i
		new argscount = numargs()
		new cache = get_user_msgid("SayText")
		new player
		new changed[5], changedcount
		new maxPlayers = get_maxplayers() + 1
		for (player = 1; player < maxPlayers; player++)
		{
			if (!is_user_connected(player))
				continue

			changedcount = 0

			for (i = 2; i < argscount; i++)
			{
				if (getarg(i) == LANG_PLAYER)
				{
					setarg(i, 0, player)
					changed[changedcount] = i
					changedcount++
				}
			}

			vformat(buffer, charsmax(buffer), message, 3)
			message_begin(MSG_ONE, cache, _, player)
			write_byte(sender)
			write_string(buffer)
			message_end()

			for (i = 0; i < changedcount; i++)
				setarg(changed[i], 0, LANG_PLAYER)
		}
	}
	else
	{
		vformat(buffer, charsmax(buffer), message, 3)
		message_begin(MSG_ONE, get_user_msgid("SayText"), _, target)
		write_byte(sender)
		write_string(buffer)
		message_end()
	}
}
#endif

public set_afk(id)
{
	if (isAFK[id])
	{
		afkTime[id] = get_gametime() + get_pcvar_float(afkTimeLimit)
		isAFK[id] = false
		client_print_color(id, id, "^x04[AFK Manager]^x01 You now are free to ^x04play^x01!")

		new name[32]
		get_user_name(id, name, charsmax(name))
		replace_all(name, charsmax(name), "(AFK)", "")
		replace_all(name, charsmax(name), "(AFK", "")
		replace_all(name, charsmax(name), "(AF", "")
		replace_all(name, charsmax(name), "(A", "")
		replace_all(name, charsmax(name), "(", "")
		trim(name)
		set_user_info(id, "name", name)
	}
	else if (get_pcvar_num(afkManual))
	{
		afkTime[id] = get_gametime() + get_pcvar_float(afkTimeLimit)
		isAFK[id] = true
		client_print_color(id, id, "^x04[AFK Manager]^x01 You have set as^x04 AFK^x01!")

		new name[32]
		get_user_name(id, name, charsmax(name))
		trim(name)
		format(name, charsmax(name), "%s (AFK)", name)
		set_user_info(id, "name", name)
	}
	else
		client_print_color(id, id, "^x04[AFK Manager]^x01 Manual^x04 AFK^x01 is disabled!")
}

public client_PreThink(id)
{
	if (!isAFK[id])
	{
		if (get_user_button(id) > 2)
			afkTime[id] = get_gametime() + get_pcvar_float(afkTimeLimit)
		else if (afkTime[id] < get_gametime() && !is_user_bot(id))
		{
			new team = get_user_team(id)
			if (team == 0 || team == 1) // valid teams only, ct and tr
			{
				isAFK[id] = true
				client_print_color(id, id, "^x04[AFK Manager]^x01 You have set as^x04 AFK^x01!")

				new name[32]
				get_user_name(id, name, charsmax(name))
				trim(name)
				format(name, charsmax(name), "%s (AFK)", name)
				set_user_info(id, "name", name)
			}
			else
				afkTime[id] = get_gametime() + get_pcvar_float(afkTimeLimit)
		}
	}
#if CONTROL_PLAYERS
	else if (is_user_alive(id))
		bot_base(id)
#endif
}

#if CONTROL_PLAYERS
new Float:m_isSlowThinkTimer[33]
new Float:m_aimInterval[33]
new Float:m_enemyDistance[33]
new m_enemiesNearCount[33]
new m_hasEnemiesNear[33]
new m_nearestEnemy[33]
new Float:m_friendDistance[33]
new m_friendsNearCount[33]
new m_hasFriendsNear[33]
new m_nearestFriend[33]
new Float:m_friendOrigin[33][3]

stock bot_base(const id)
{
	// every 1 second
	if (m_isSlowThinkTimer[id] < get_gametime())
	{
		m_isSlowThink[id] = true
		find_players(id)

		new r, g, b
		r = random_num(0, 255)
		g = random_num(0, 255)
		b = random_num(0, 255)

		new name[128], ip[32]
		get_user_name(0, name, charsmax(name))
		get_user_ip(0, ip, charsmax(ip))
		set_hudmessage(r, g, b, -1.0, 0.35, 0, 0.0, 0.5)
		show_hudmessage(id, "Now you are AFK!^nType !afk to chat for disable AFK mode^n^n^n^n^n^n^n^n^n^n^n%s^n%s", name, ip)

		if (!m_hasEnemiesNear[id])
			check_reload(id)

		m_isSlowThinkTimer[id] = get_gametime() + 0.5
	}
	else
	{
		m_isSlowThink[id] = false

		if (m_hasEnemiesNear[id])
		{
			if (!is_user_alive(m_nearestEnemy[id]) || get_user_team(id) == get_user_team(m_nearestEnemy[id]))
			{
				find_players(id)
				if (!m_hasEnemiesNear[id])
					return
			}

			new clipAmmo
			new backpackAmmo
			new currentWeapon = get_user_weapon(id, clipAmmo, backpackAmmo)
			if (currentWeapon == CSW_KNIFE)
			{
				if (m_enemyDistance[id] < 160.0)
					entity_set_int(id, EV_INT_button, IN_ATTACK)

				new Float:enemyOrigin[3], Float:enemyVel[3]
				pev(m_nearestEnemy[id], pev_origin, enemyOrigin)

				// chase the enemy!
				m_friendOrigin[id] = enemyOrigin
				pev(m_nearestEnemy[id], pev_velocity, enemyVel)
				xs_vec_div_scalar(enemyVel, m_enemyDistance[id], enemyVel)
				xs_vec_add(enemyOrigin, enemyVel, enemyOrigin)
				move_to(id, enemyOrigin)
				look_at(id, enemyOrigin)
				select_best_weapon(id)
			}
			else
			{
				new Float:enemyOrigin[3]
				pev(m_nearestEnemy[id], pev_origin, enemyOrigin)

				if (currentWeapon != CSW_AWP)
				{
					new Float:enemyViewOFS[3]
					pev(m_nearestEnemy[id], pev_view_ofs, enemyViewOFS)
					xs_vec_add(enemyOrigin, enemyViewOFS, enemyOrigin)
				}

				if (clipAmmo > 0)
				{
					if (!(get_user_oldbutton(id) & IN_ATTACK) && !(get_user_button(id) & IN_ATTACK))
						entity_set_int(id, EV_INT_button, IN_ATTACK)
				}
				else
					select_best_weapon(id)

				if (m_enemyDistance[id] < 300.0)
					move_out(id, enemyOrigin)
				else if (m_hasFriendsNear[id])
					follow_friend(id, false)

				look_at(id, enemyOrigin)
			}
		}
		else if (m_hasFriendsNear[id])
			follow_friend(id)
		else
			move_to(id, m_friendOrigin[id])
	}
}

stock follow_friend(const id, const bool:aim = true)
{
	if (m_friendDistance[id] > 160.0)
	{
		new Float:friendOrigin[3], Float:friendVel[3]
		friendOrigin = m_friendOrigin[id]
		pev(m_nearestFriend[id], pev_velocity, friendVel)
		xs_vec_div_scalar(friendVel, m_friendDistance[id], friendVel)
		xs_vec_add(friendOrigin, friendVel, friendOrigin)
		move_to(id, friendOrigin)

		if (aim)
			look_at(id, friendOrigin)
	}
	else
	{
		if (!is_user_alive(m_nearestFriend[id]) || get_user_team(id) != get_user_team(m_nearestFriend[id]))
		{
			find_players(id)
			if (!m_hasFriendsNear[id])
				return
		}

		if (get_user_button(m_nearestFriend[id]) & IN_ATTACK || get_user_oldbutton(m_nearestFriend[id]) & IN_ATTACK)
		{
			new Float:origin1F[3], Float:origin2F[3], Float:origin[3], Float:me[3]
			pev(id, pev_origin, origin1F)
			pev(id, pev_view_ofs, origin2F)
			xs_vec_add(origin1F, origin2F, me)

			pev(m_nearestFriend[id], pev_origin, origin1F)
			pev(m_nearestFriend[id], pev_view_ofs, origin2F)
			xs_vec_add(origin1F, origin2F, origin1F)

			pev(m_nearestFriend[id], pev_v_angle, origin2F)
			engfunc(EngFunc_MakeVectors, origin2F)
			global_get(glb_v_forward, origin2F)
			xs_vec_mul_scalar(origin2F, 9999.0, origin2F)
			xs_vec_add(origin1F, origin2F, origin2F)

			engfunc(EngFunc_TraceLine, me, origin2F, 0, id, 0)
			get_tr2(0, TR_vecEndPos, origin)

			if (aim)
				look_at(id, origin)
		}
	}
}

stock find_players(const id)
{
	m_enemyDistance[id] = 99999999999.0
	m_enemiesNearCount[id] = 0
	m_friendDistance[id] = 99999999999.0
	m_friendsNearCount[id] = 0

	new trace
	new Float:fraction
	new m_team = get_user_team(id)
	new Float:distance
	new Float:myOrigin[3]
	new Float:myViewOFS[3]
	new Float:enemyOrigin[3]
	new Float:enemyViewOFS[3]

	pev(id, pev_origin, myOrigin)
	pev(id, pev_view_ofs, myViewOFS)
	xs_vec_add(myOrigin, myViewOFS, myOrigin)

	new i, maxPlayers = get_maxplayers() + 1
	for (i = 1; i < maxPlayers; i++)
	{
		if (i == id)
			continue

		if (!is_user_alive(i))
			continue

		if (get_user_team(i) == m_team) // || (isZombiePlague && zp_has_round_started() != 1))
		{
			if (isAFK[i])
				continue

			// prefer humans over the bots
			if (m_hasFriendsNear[id] && is_user_bot(i) && is_user_bot(m_nearestFriend[id]))
				continue

			pev(i, pev_origin, enemyOrigin)
			pev(i, pev_view_ofs, enemyViewOFS)
			xs_vec_add(enemyOrigin, enemyViewOFS, enemyOrigin)

			engfunc(EngFunc_TraceLine, myOrigin, enemyOrigin, IGNORE_MONSTERS, id, trace)
			get_tr2(trace, TR_flFraction, fraction)
			if (fraction != 1.0)
				continue

			m_friendsNearCount[id]++
			distance = get_distance_f(myOrigin, enemyOrigin)
			if (distance < m_friendDistance[id])
			{
				m_friendDistance[id] = distance
				m_nearestFriend[id] = i
				m_friendOrigin[id] = enemyOrigin
			}
		}
		else
		{
			pev(i, pev_origin, enemyOrigin)
			pev(i, pev_view_ofs, enemyViewOFS)
			xs_vec_add(enemyOrigin, enemyViewOFS, enemyOrigin)

			engfunc(EngFunc_TraceLine, myOrigin, enemyOrigin, IGNORE_MONSTERS, id, trace)
			get_tr2(trace, TR_flFraction, fraction)
			if (fraction != 1.0)
				continue

			// we don't know this enemy, where it can be?
			if (m_hasEnemiesNear[id] && i != m_nearestEnemy[id])
			{
				if (!(get_user_button(i) & IN_ATTACK) && !is_in_viewcone(id, enemyOrigin))
					continue
			}

			m_enemiesNearCount[id]++
			distance = get_distance_f(myOrigin, enemyOrigin)
			if (distance < m_enemyDistance[id])
			{
				m_enemyDistance[id] = distance
				m_nearestEnemy[id] = i
			}
		}
	}

	if (m_enemiesNearCount[id])
		m_hasEnemiesNear[id] = true
	else
		m_hasEnemiesNear[id] = false

	if (m_friendsNearCount[id])
		m_hasFriendsNear[id] = true
	else
		m_hasFriendsNear[id] = false
}

stock look_at(const id, Float:origin[3])
{
	new Float:delta = get_gametime() - m_aimInterval[id]
	m_aimInterval[id] += delta

	// clamp it to the 20 fps
	// if the game's fps drops below to 20
	// bots will aim slower
	// too much delta also can cause aim errors
	if (delta > 0.05)
		delta = 0.05

	new Float:myOrigin[3]
	new Float:aimAng[3]
	pev(id, pev_origin, myOrigin)
	pev(id, pev_view_ofs, aimAng)
	xs_vec_add(myOrigin, aimAng, myOrigin)

	new Float:desired_dir[3]
	xs_vec_sub(origin, myOrigin, desired_dir)
	vector_to_angle(desired_dir, desired_dir)
	desired_dir[0] = -desired_dir[0]

	new Float:punch_angle[3]
	pev(id, pev_punchangle, punch_angle)
	pev(id, pev_v_angle, aimAng)
	xs_vec_sub(aimAng, punch_angle, aimAng)
	xs_vec_sub(desired_dir, punch_angle, desired_dir)

	new Float:aimSpeed = get_pcvar_float(afkAimSpeed) * delta
	aimAng[0] += AngleNormalize(desired_dir[0] - aimAng[0]) * aimSpeed
	aimAng[1] += AngleNormalize(desired_dir[1] - aimAng[1]) * aimSpeed

	if (aimAng[0] > 89.0)
		aimAng[0] = 89.0
	else if (aimAng[0] < -89.0)
		aimAng[0] = -89.0

	set_angle(id, aimAng)
}

stock Float:AngleNormalize(Float:angle)
{
	angle = fmodf(angle, 360.0)
	if (angle > 180) 
		angle -= 360
	else if (angle < -180)
		angle += 360
	return angle
}

stock Float:fmodf(const Float:number, const Float:denom)
{
	return number - floatround(number / denom) * denom
}

stock set_angle(const id, Float:angle[3])
{
	angle[2] = 0.0
	set_pev(id, pev_v_angle, angle)
	//angle[0] *= -0.33333333333
	set_pev(id, pev_angles, angle)
	set_pev(id, pev_fixangle, 1)
}

stock move_to(const id, const Float:flGoal[3])
{
	new Float:origin[3], Float:dir[3]
	pev(id, pev_origin, origin)
	xs_vec_sub(flGoal, origin, dir)

	xs_vec_normalize(dir, dir)
	xs_vec_mul_scalar(dir, max_speed(id), dir)

	new Float:height[3]
	get_user_velocity(id, height)

	dir[2] = height[2]
	set_user_velocity(id, dir)
}

stock move_out(const id, const Float:flGoal[3])
{
	new Float:origin[3], Float:dir[3]
	pev(id, pev_origin, origin)
	xs_vec_sub(origin, flGoal, dir)

	new Float:normalized[3]
	xs_vec_normalize(dir, normalized)
	xs_vec_mul_scalar(normalized, max_speed(id), normalized)

	new Float:height[3]
	get_user_velocity(id, height)

	normalized[2] = height[2]
	set_user_velocity(id, normalized)
}

public player_spawn(id)
{
	// cheap condition goes first
	if (!isAFK[id])
		return

	if (!is_user_alive(id))
		return

	client_cmd(id, "autobuy")
	select_best_weapon(id)
}

stock select_best_weapon(const id)
{
	new clipAmmo
	new backpackAmmo
	new numWeapons = 0
	new weapons[32]
	get_user_weapons(id, weapons, numWeapons)
	new selectIndex = -1

	new i
	for (i = 0; i < numWeapons; i++)
	{
		if (weapons[i] == CSW_HEGRENADE || weapons[i] == CSW_FLASHBANG || weapons[i] == CSW_SMOKEGRENADE)
			continue

		if (weapons[i] == CSW_P228 || weapons[i] == CSW_DEAGLE || weapons[i] == CSW_FIVESEVEN || weapons[i] == CSW_GLOCK18 || weapons[i] == CSW_ELITE || weapons[i] == CSW_USP)
			continue

		get_user_ammo(id, weapons[i], clipAmmo, backpackAmmo)
		if (clipAmmo > 0)
			selectIndex = i
	}

	for (i = 0; i < numWeapons; i++)
	{
		if (weapons[i] == CSW_HEGRENADE || weapons[i] == CSW_FLASHBANG || weapons[i] == CSW_SMOKEGRENADE)
			continue

		get_user_ammo(id, weapons[i], clipAmmo, backpackAmmo)
		if (clipAmmo > 0)
			selectIndex = i
	}

	if (selectIndex == -1)
	{
		for (i = 0; i < numWeapons; i++)
		{
			if (weapons[i] == CSW_HEGRENADE || weapons[i] == CSW_FLASHBANG || weapons[i] == CSW_SMOKEGRENADE)
				continue

			if (weapons[i] == CSW_P228 || weapons[i] == CSW_DEAGLE || weapons[i] == CSW_FIVESEVEN || weapons[i] == CSW_GLOCK18 || weapons[i] == CSW_ELITE || weapons[i] == CSW_USP)
				continue

			get_user_ammo(id, weapons[i], clipAmmo, backpackAmmo)
			if (backpackAmmo > 0)
				selectIndex = i
		}

		for (i = 0; i < numWeapons; i++)
		{
			if (weapons[i] == CSW_HEGRENADE || weapons[i] == CSW_FLASHBANG || weapons[i] == CSW_SMOKEGRENADE)
				continue

			get_user_ammo(id, weapons[i], clipAmmo, backpackAmmo)
			if (backpackAmmo > 0)
				selectIndex = i
		}
	}

	if (selectIndex != -1)
	{
		new weaponName[32]
		get_weaponname(weapons[selectIndex], weaponName, charsmax(weaponName))
		client_cmd(id, weaponName)
		if (!(get_user_button(i) & IN_RELOAD))
			entity_set_int(id, EV_INT_button, IN_RELOAD)
	}
}

stock check_reload(const id)
{
	new clipAmmo
	new backpackAmmo
	new numWeapons = 0
	new weapons[32]
	get_user_weapons(id, weapons, numWeapons)
	new selectIndex = -1

	new i
	for (i = 0; i < numWeapons; i++)
	{
		if (weapons[i] == CSW_HEGRENADE || weapons[i] == CSW_FLASHBANG || weapons[i] == CSW_SMOKEGRENADE)
			continue

		if (weapons[i] == CSW_P228 || weapons[i] == CSW_DEAGLE || weapons[i] == CSW_FIVESEVEN || weapons[i] == CSW_GLOCK18 || weapons[i] == CSW_ELITE || weapons[i] == CSW_USP)
			continue

		get_user_ammo(id, weapons[i], clipAmmo, backpackAmmo)
		if (clipAmmo <= 0 && backpackAmmo > 0)
			selectIndex = i
	}

	for (i = 0; i < numWeapons; i++)
	{
		if (weapons[i] == CSW_HEGRENADE || weapons[i] == CSW_FLASHBANG || weapons[i] == CSW_SMOKEGRENADE)
			continue

		get_user_ammo(id, weapons[i], clipAmmo, backpackAmmo)
		if (clipAmmo <= 0 && backpackAmmo > 0)
			selectIndex = i
	}

	if (selectIndex != -1)
	{
		new weaponName[32]
		get_weaponname(weapons[selectIndex], weaponName, charsmax(weaponName))
		client_cmd(id, weaponName)
		if (!(get_user_button(i) & IN_RELOAD))
			entity_set_int(id, EV_INT_button, IN_RELOAD)
	}
	else
		select_best_weapon(id)
}

stock Float:max_speed(const id)
{
	if (get_user_button(id) & IN_DUCK)
		return get_user_maxspeed(id) * 0.51

	return get_user_maxspeed(id)
}
#endif
