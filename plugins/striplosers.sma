
#define PLUGIN_NAME "Strip Losers"
#define PLUGIN_VERSION "1.2.0"
#define AUTHOR_NAME "thurinven"

#define PLUGIN_TAG "striplosers.amxx"

#include <amxmodx>
#include <cstrike>
#include <fun>
#include <fakemeta>
#include <WPMGPrintChatColor>

new sl_enabled
new sl_prefix
new has_team_advantage

new pendingPlayers[32]
new pendingPlayersSize

public plugin_init()
{
	register_plugin(PLUGIN_NAME, PLUGIN_VERSION, AUTHOR_NAME)

	register_event("SendAudio", "OnRoundEnd", "a", "2=%!MRAD_terwin", "2=%!MRAD_ctwin", "2=%!MRAD_rounddraw")
	register_event("HLTV", "OnHLTVNewRound", "a", "1=0", "2=0")
	register_forward(FM_Touch, "fwdTouch")

	sl_enabled = register_cvar("sl_enabled", "3", FCVAR_SERVER)
	sl_prefix = register_cvar("sl_prefix", "!y(!gKniajevo CS!y)", FCVAR_SERVER)

	has_team_advantage = is_plugin_loaded("Team Advantage")
	server_print("[%s] Team Advantage is loaded. Money will not be reset.", PLUGIN_TAG)
}

bool:isPending(id) 
{
	for (new i = 0; i < pendingPlayersSize; ++i)
	{
		if (pendingPlayers[i] == id)
			return true
	}

	return false
}
 
public fwdTouch(ent, id)
{
	if (!is_user_connected(id) || !is_user_alive(id) || !isPending(id))
			return FMRES_IGNORED

	new class[32]
	pev(ent, pev_classname, class, 31)

	if (equali(class, "weaponbox") || equali(class, "armoury_entity") || equali(class, "weapon_shield") || equali(class, "grenade"))
			return FMRES_SUPERCEDE

	return FMRES_IGNORED
}

public OnHLTVNewRound()
{
	pendingPlayersSize = 0
}

public ResetWeapons(id)
{
	strip_user_weapons(id)
	give_item(id, "weapon_knife")

	if (cs_get_user_team(id) == CS_TEAM_CT) 
	{
		give_item(id, "weapon_usp")
		cs_set_user_bpammo(id, CSW_USP, 24)
	} 
	else 
	{
		give_item(id, "weapon_glock18")
		cs_set_user_bpammo(id, CSW_GLOCK18, 40)
	}
}

public ChangeMoney(parm[])
{
	new player[32], playersnum
	new id

	get_players(player, playersnum, "ea", (parm[7] == 't') ? "CT" : "TERRORIST" )

	if (playersnum > 0)
	{
		new prefix[32]
		get_pcvar_string(sl_prefix, prefix, 32)

		PrintChatColor(0, PRINT_COLOR_PLAYERTEAM, "%s !t%s !yfailed to complete their objectives. Their weapons will be stripped.", prefix, (parm[7] == 't') ? "Counter-Terrorists" : "Terrorists")
		server_print("Losers are %s, Players: %d", ((parm[7] == 't') ? "CT" : "TERRORIST") , playersnum)
	}

	for (new i = 0; i < playersnum; ++i)
	{
		id = player[i]

		set_hudmessage(178, 14, 41, -1.0, -0.4, 1, 0.5, 1.7, 0.2, 0.2, -1);
		show_hudmessage(id, "Objective Failed^nYour weapons will be reset" );

		pendingPlayers[i] = id
		++pendingPlayersSize

		new mode = get_pcvar_num(sl_enabled)
		if (mode == 1 || mode == 3)
			ResetWeapons(id)
		if (!has_team_advantage && mode > 1)
			cs_set_user_money(id, get_cvar_num("mp_startmoney"))
	}
}

public OnRoundEnd()
{
	new mode = get_pcvar_num(sl_enabled)
	if (mode)
	{
		new parm[32]
		new len = read_data(2, parm, charsmax(parm))

		set_task(0.1, "ChangeMoney", mode == 2, parm, len + 1)
	}
}
