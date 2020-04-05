
#define PLUGIN_NAME "Strip Losers"
#define PLUGIN_VERSION "1.0.0"
#define AUTHOR_NAME "thurinven"

#define PLUGIN_TAG "striplosers.amxx"

#include <amxmodx>
#include <cstrike>
#include <fun>
#include <WPMGPrintChatColor>

new amx_striplosers

public plugin_init()
{
	register_plugin(PLUGIN_NAME, PLUGIN_VERSION, AUTHOR_NAME)
	register_event("SendAudio", "end_round", "a", "2=%!MRAD_terwin", "2=%!MRAD_ctwin", "2=%!MRAD_rounddraw")

	amx_striplosers = register_cvar("amx_striplosers", "1", FCVAR_SERVER)
}

public end_round()
{
	new mode = get_pcvar_num(amx_striplosers)
	if (mode)
	{
		new parm[32]
		new len = read_data(2, parm, charsmax(parm))

		set_task(0.1, "change_money", mode == 2, parm, len + 1)
	}
}

public change_money(parm[])
{
	new origin[3], srco[3]
	new player[32], playersnum
	new id

	get_players(player, playersnum, "ea", (parm[7] == 't') ? "CT" : "TERRORIST" )

	if (playersnum > 0)
	{
		PrintChatColor(0, PRINT_COLOR_PLAYERTEAM, "!y(!gKniajevo CS!y) !t%s !yfailed to complete their objectives. Their weapons will be stripped.", (parm[7] == 't') ? "Counter-Terrorists" : "Terrorists")
		server_print("Losers are %s, Players: %d", ((parm[7] == 't') ? "CT" : "TERRORIST") , playersnum)
	}

	for (new i = 0; i < playersnum; ++i)
	{
		id = player[i]

		set_hudmessage(178, 14, 41, -1.0, -0.4, 1, 0.5, 1.7, 0.2, 0.2, -1);
		show_hudmessage(id, "Objective Failed^nYour money and weapons have been reset" );

		strip_user_weapons(id)
		give_item(id, "weapon_knife")

		if (parm[7] == 't') 
		{
			give_item(id, "weapon_usp")
			cs_set_user_bpammo(id, CSW_USP, 24)
		} 
		else 
		{
			give_item(id, "weapon_glock18")
			cs_set_user_bpammo(id, CSW_GLOCK18, 40)
		}

		cs_set_user_money(id, get_cvar_num("mp_startmoney"))
	}
}
