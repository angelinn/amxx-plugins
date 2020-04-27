#include <amxmodx>
#include <reapi>

#define PLUGIN_VERSION "1.0"
#define VIP_FLAG ADMIN_LEVEL_A

// slap, slay, gag, vote, def kit, nades

new bool: hasBombSite

public plugin_init()
{
	register_plugin("VIP Manager", PLUGIN_VERSION, "thurinven")

	RegisterHookChain(RG_CBasePlayer_Spawn, "OnPlayerSpawn", 1)
	register_message(get_user_msgid("ScoreAttrib"), "OnScoreAttrib")

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
	if(is_user_vip(get_msg_arg_int(1)))
		set_msg_arg_int(2, ARG_BYTE, (1<<2))
}

bool:is_user_vip(id)
	return !!(get_user_flags(id) & VIP_FLAG)
