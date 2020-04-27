#include <amxmodx>
#include <reapi>

#define PLUGIN_VERSION "1.7"
#define VIP_FLAG ADMIN_LEVEL_A

// slap, slay, gag, vote, def kit, nades

enum ( <<= 1 )
{
    SCOREATTRIB_FLAG_NONE = 0,
    SCOREATTRIB_FLAG_DEFAULT = 1,
    SCOREATTRIB_FLAG_BOMB,
    SCOREATTRIB_FLAG_VIP
};

new bool: hasBombSite
new gmsgSayText

public plugin_init()
{
	register_plugin("VIP Manager", PLUGIN_VERSION, "thurinven")

	RegisterHookChain(RG_CBasePlayer_Spawn, "OnPlayerSpawn", 1)
	register_message(get_user_msgid("ScoreAttrib"), "OnScoreAttrib")
	register_clcmd("say", "handle_say")

	gmsgSayText = get_user_msgid("SayText")

	if (rg_find_ent_by_class(-1, "func_bomb_target") > 0 || rg_find_ent_by_class(-1, "info_bomb_target") > 0)
		hasBombSite = true
}

public OnPlayerSpawn(id)
{
	if (!is_user_alive(id) || !is_user_vip(id))
		return

	rg_give_item(id, "weapon_flashbang", GT_REPLACE)
	rg_set_user_bpammo(id, CSW_FLASHBANG, 2)
	rg_give_item(id, "weapon_hegrenade")
	rg_give_item(id, "weapon_deagle", GT_REPLACE)    
	rg_set_user_bpammo(id, CSW_DEAGLE, 35)

	if (hasBombSite && get_member(id, m_iTeam) == TEAM_CT)
	{
		rg_give_defusekit(id)
	}
}

public OnScoreAttrib(iMsgId, iMsgDest, iMsgEnt)
{
	new iPlayer = get_msg_arg_int(1)

	if(is_user_vip(iPlayer))
	    set_msg_arg_int( 2, ARG_BYTE, is_user_alive( iPlayer ) ? SCOREATTRIB_FLAG_VIP : SCOREATTRIB_FLAG_DEFAULT )
}

bool:is_user_vip(id, bool:includeAdmin = true)
{
	new flags = get_user_flags(id)
	if (includeAdmin)
		return !!(flags & VIP_FLAG)

	return !(flags & ADMIN_IMMUNITY) && !!(flags & VIP_FLAG)
}

// Modified admin check below to show vips
public handle_say(id)
{
	new said[192]
	read_args(said,192)

	if(contain(said, "/vip") != -1 || contain(said, "/vips") != -1)
		set_task(0.1, "print_viplist", id)

	return PLUGIN_CONTINUE
}

public print_viplist(user) 
{
	new vipnames[33][32]
	new message[256]
	new id, count, x, len
	new maxplayers = get_maxplayers()
	
	for(id = 1 ; id <= maxplayers ; id++)
	{
		if(is_user_connected(id))
		{
			if(is_user_vip(id, false))
				get_user_name(id, vipnames[count++], 31)
		}
	}

	len = format(message, 255, "%s Vips online: ","^x04")
	if(count > 0) {
		for(x = 0 ; x < count ; x++) {
			len += format(message[len], 255-len, "%s%s ", vipnames[x], x < (count-1) ? ", ":"")
			if(len > 96 ) {
				print_message(user, message)
				len = format(message, 255, "%s ","^x04")
			}
		}
		print_message(user, message)
	}
	else {
		len += format(message[len], 255-len, "No vips online.")
		print_message(user, message)
	}
}

print_message(id, msg[])
{
	message_begin(MSG_ONE, gmsgSayText, {0,0,0}, id)
	write_byte(id)
	write_string(msg)
	message_end()
}